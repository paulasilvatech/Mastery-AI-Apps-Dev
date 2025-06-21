# Exercise 2: Database Migration Agent (⭐⭐ Medium - 45 minutes)

## 🎯 Objective
Build an intelligent database migration agent that analyzes schema changes, generates safe migration scripts, validates data integrity, and provides rollback capabilities for multiple database systems.

## 🧠 What You'll Learn
- Schema analysis and comparison
- Safe migration generation
- Data validation strategies
- Rollback mechanism implementation
- Multi-database support

## 📋 Prerequisites
- Completed Exercise 1
- Understanding of SQL and database schemas
- Knowledge of database migrations
- Familiarity with SQLAlchemy or similar ORMs

## 📚 Background

A database migration agent must:
- Detect schema differences
- Generate migration scripts
- Ensure data integrity
- Provide rollback capabilities
- Handle multiple database types
- Track migration history

## 🛠️ Instructions

### Step 1: Design the Migration Agent Architecture

**Copilot Prompt Suggestion:**
```python
# Create a database migration agent that:
# - Analyzes current and target schemas
# - Detects all types of schema changes
# - Generates safe migration scripts
# - Validates data before and after migration
# - Provides automatic rollback on failure
# - Supports PostgreSQL, MySQL, and SQLite
# - Tracks migration history
# Use strategy pattern for database-specific operations
```

Create `src/agents/migration_agent.py`:
```python
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import List, Dict, Any, Optional, Tuple, Set
from enum import Enum
from datetime import datetime
import hashlib
import sqlalchemy as sa
from sqlalchemy import inspect, MetaData
from sqlalchemy.engine import Engine
import json

class ChangeType(Enum):
    """Types of schema changes"""
    CREATE_TABLE = "create_table"
    DROP_TABLE = "drop_table"
    ADD_COLUMN = "add_column"
    DROP_COLUMN = "drop_column"
    ALTER_COLUMN = "alter_column"
    ADD_INDEX = "add_index"
    DROP_INDEX = "drop_index"
    ADD_CONSTRAINT = "add_constraint"
    DROP_CONSTRAINT = "drop_constraint"

class MigrationStatus(Enum):
    """Migration execution status"""
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    FAILED = "failed"
    ROLLED_BACK = "rolled_back"

@dataclass
class SchemaChange:
    """Represents a single schema change"""
    change_type: ChangeType
    table_name: str
    details: Dict[str, Any]
    forward_sql: str
    backward_sql: Optional[str]
    data_migration: Optional[str] = None
    validation_query: Optional[str] = None
    risk_level: str = "low"  # low, medium, high

@dataclass
class Migration:
    """Represents a complete migration"""
    id: str
    name: str
    changes: List[SchemaChange]
    created_at: datetime
    executed_at: Optional[datetime] = None
    status: MigrationStatus = MigrationStatus.PENDING
    checksum: Optional[str] = None
    execution_time: Optional[float] = None
    error: Optional[str] = None

@dataclass
class MigrationPlan:
    """Execution plan for migrations"""
    migrations: List[Migration]
    pre_checks: List[Dict[str, Any]]
    post_checks: List[Dict[str, Any]]
    estimated_downtime: float
    total_risk_score: int

class DatabaseMigrationAgent:
    """Intelligent agent for database migrations"""
    
    def __init__(self, connection_string: str):
        self.engine = sa.create_engine(connection_string)
        self.metadata = MetaData()
        self.inspector = inspect(self.engine)
        self.dialect = self.engine.dialect.name
        self.strategy = self._get_strategy()
        self.history_table = self._setup_history_table()
        
    def _get_strategy(self) -> 'DatabaseStrategy':
        """Get database-specific strategy"""
        strategies = {
            'postgresql': PostgreSQLStrategy(),
            'mysql': MySQLStrategy(),
            'sqlite': SQLiteStrategy()
        }
        return strategies.get(self.dialect, GenericStrategy())
    
    def _setup_history_table(self) -> sa.Table:
        """Create migration history table"""
        table = sa.Table(
            'migration_history',
            self.metadata,
            sa.Column('id', sa.String(50), primary_key=True),
            sa.Column('name', sa.String(200), nullable=False),
            sa.Column('checksum', sa.String(64), nullable=False),
            sa.Column('executed_at', sa.DateTime, nullable=False),
            sa.Column('execution_time', sa.Float),
            sa.Column('status', sa.String(20), nullable=False),
            sa.Column('changes', sa.Text),
            sa.Column('error', sa.Text),
            extend_existing=True
        )
        
        table.create(self.engine, checkfirst=True)
        return table
    
    def analyze_schema_diff(self, target_metadata: MetaData) -> List[SchemaChange]:
        """Analyze differences between current and target schema"""
        current_metadata = self._get_current_metadata()
        changes = []
        
        # Detect table changes
        current_tables = set(current_metadata.tables.keys())
        target_tables = set(target_metadata.tables.keys())
        
        # New tables
        for table_name in target_tables - current_tables:
            change = self._analyze_create_table(target_metadata.tables[table_name])
            changes.append(change)
        
        # Dropped tables
        for table_name in current_tables - target_tables:
            change = self._analyze_drop_table(current_metadata.tables[table_name])
            changes.append(change)
        
        # Modified tables
        for table_name in current_tables & target_tables:
            table_changes = self._analyze_table_changes(
                current_metadata.tables[table_name],
                target_metadata.tables[table_name]
            )
            changes.extend(table_changes)
        
        return changes
    
    def _analyze_create_table(self, table: sa.Table) -> SchemaChange:
        """Analyze new table creation"""
        forward_sql = self.strategy.generate_create_table(table)
        backward_sql = self.strategy.generate_drop_table(table)
        
        return SchemaChange(
            change_type=ChangeType.CREATE_TABLE,
            table_name=table.name,
            details={
                'columns': [col.name for col in table.columns],
                'primary_key': [col.name for col in table.primary_key]
            },
            forward_sql=forward_sql,
            backward_sql=backward_sql,
            risk_level="low"
        )
    
    def _analyze_drop_table(self, table: sa.Table) -> SchemaChange:
        """Analyze table deletion"""
        # Check for data
        row_count = self._get_table_row_count(table.name)
        risk_level = "high" if row_count > 0 else "medium"
        
        forward_sql = self.strategy.generate_drop_table(table)
        backward_sql = self.strategy.generate_create_table(table)
        
        return SchemaChange(
            change_type=ChangeType.DROP_TABLE,
            table_name=table.name,
            details={
                'row_count': row_count,
                'has_foreign_keys': len(table.foreign_keys) > 0
            },
            forward_sql=forward_sql,
            backward_sql=backward_sql,
            risk_level=risk_level
        )
    
    def _analyze_table_changes(self, current: sa.Table, target: sa.Table) -> List[SchemaChange]:
        """Analyze changes within a table"""
        changes = []
        
        # Column changes
        current_cols = {col.name: col for col in current.columns}
        target_cols = {col.name: col for col in target.columns}
        
        # New columns
        for col_name in set(target_cols.keys()) - set(current_cols.keys()):
            change = self._analyze_add_column(target, target_cols[col_name])
            changes.append(change)
        
        # Dropped columns
        for col_name in set(current_cols.keys()) - set(target_cols.keys()):
            change = self._analyze_drop_column(current, current_cols[col_name])
            changes.append(change)
        
        # Modified columns
        for col_name in set(current_cols.keys()) & set(target_cols.keys()):
            if self._column_changed(current_cols[col_name], target_cols[col_name]):
                change = self._analyze_alter_column(
                    current, current_cols[col_name], target_cols[col_name]
                )
                changes.append(change)
        
        # Index changes
        index_changes = self._analyze_index_changes(current, target)
        changes.extend(index_changes)
        
        # Constraint changes
        constraint_changes = self._analyze_constraint_changes(current, target)
        changes.extend(constraint_changes)
        
        return changes
    
    def _column_changed(self, current: sa.Column, target: sa.Column) -> bool:
        """Check if column definition changed"""
        # Compare type, nullable, default, etc.
        if type(current.type) != type(target.type):
            return True
        if current.nullable != target.nullable:
            return True
        if current.default != target.default:
            return True
        return False
    
    def create_migration_plan(self, changes: List[SchemaChange], 
                            name: str = None) -> MigrationPlan:
        """Create execution plan from changes"""
        # Group related changes
        grouped_changes = self._group_related_changes(changes)
        
        # Create migrations
        migrations = []
        for i, change_group in enumerate(grouped_changes):
            migration_name = name or f"migration_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{i}"
            migration = Migration(
                id=f"{migration_name}_{i}",
                name=migration_name,
                changes=change_group,
                created_at=datetime.now(),
                checksum=self._calculate_checksum(change_group)
            )
            migrations.append(migration)
        
        # Create pre and post checks
        pre_checks = self._generate_pre_checks(changes)
        post_checks = self._generate_post_checks(changes)
        
        # Estimate downtime and risk
        estimated_downtime = self._estimate_downtime(changes)
        total_risk_score = self._calculate_risk_score(changes)
        
        return MigrationPlan(
            migrations=migrations,
            pre_checks=pre_checks,
            post_checks=post_checks,
            estimated_downtime=estimated_downtime,
            total_risk_score=total_risk_score
        )
    
    def execute_migration_plan(self, plan: MigrationPlan, 
                             dry_run: bool = False) -> Dict[str, Any]:
        """Execute migration plan with safety checks"""
        results = {
            'success': True,
            'executed_migrations': [],
            'failed_migration': None,
            'rollback_performed': False,
            'execution_time': 0
        }
        
        start_time = datetime.now()
        
        # Run pre-checks
        if not self._run_pre_checks(plan.pre_checks):
            results['success'] = False
            results['error'] = "Pre-checks failed"
            return results
        
        # Execute migrations
        for migration in plan.migrations:
            try:
                if dry_run:
                    self._dry_run_migration(migration)
                else:
                    self._execute_migration(migration)
                    
                results['executed_migrations'].append(migration.id)
                
            except Exception as e:
                results['success'] = False
                results['failed_migration'] = migration.id
                results['error'] = str(e)
                
                # Rollback if needed
                if not dry_run and results['executed_migrations']:
                    self._rollback_migrations(results['executed_migrations'])
                    results['rollback_performed'] = True
                    
                break
        
        # Run post-checks if successful
        if results['success'] and not dry_run:
            if not self._run_post_checks(plan.post_checks):
                results['success'] = False
                results['error'] = "Post-checks failed"
                
                # Rollback
                self._rollback_migrations(results['executed_migrations'])
                results['rollback_performed'] = True
        
        results['execution_time'] = (datetime.now() - start_time).total_seconds()
        return results
    
    def _execute_migration(self, migration: Migration):
        """Execute a single migration"""
        migration.status = MigrationStatus.IN_PROGRESS
        start_time = datetime.now()
        
        with self.engine.begin() as conn:
            try:
                # Execute each change
                for change in migration.changes:
                    conn.execute(sa.text(change.forward_sql))
                    
                    # Run data migration if needed
                    if change.data_migration:
                        conn.execute(sa.text(change.data_migration))
                    
                    # Validate change
                    if change.validation_query:
                        result = conn.execute(sa.text(change.validation_query))
                        if not result.scalar():
                            raise Exception(f"Validation failed for {change.change_type}")
                
                # Record in history
                self._record_migration_success(migration, start_time)
                migration.status = MigrationStatus.COMPLETED
                
            except Exception as e:
                migration.status = MigrationStatus.FAILED
                migration.error = str(e)
                self._record_migration_failure(migration, start_time, str(e))
                raise
    
    def _rollback_migrations(self, migration_ids: List[str]):
        """Rollback executed migrations"""
        # Get migrations in reverse order
        migrations = self._get_migrations_by_ids(migration_ids)
        migrations.reverse()
        
        for migration in migrations:
            with self.engine.begin() as conn:
                # Execute backward SQL for each change
                for change in reversed(migration.changes):
                    if change.backward_sql:
                        conn.execute(sa.text(change.backward_sql))
                
                # Update history
                self._record_rollback(migration)
    
    def _get_current_metadata(self) -> MetaData:
        """Get current database metadata"""
        metadata = MetaData()
        metadata.reflect(bind=self.engine)
        return metadata
    
    def _get_table_row_count(self, table_name: str) -> int:
        """Get row count for a table"""
        query = sa.text(f"SELECT COUNT(*) FROM {table_name}")
        with self.engine.connect() as conn:
            result = conn.execute(query)
            return result.scalar()
    
    def _calculate_checksum(self, changes: List[SchemaChange]) -> str:
        """Calculate checksum for changes"""
        content = json.dumps([
            {
                'type': c.change_type.value,
                'table': c.table_name,
                'sql': c.forward_sql
            }
            for c in changes
        ], sort_keys=True)
        return hashlib.sha256(content.encode()).hexdigest()
    
    def _group_related_changes(self, changes: List[SchemaChange]) -> List[List[SchemaChange]]:
        """Group related changes that should execute together"""
        # Simple grouping by table and risk
        groups = {}
        
        for change in changes:
            key = (change.table_name, change.risk_level)
            if key not in groups:
                groups[key] = []
            groups[key].append(change)
        
        return list(groups.values())
    
    def _generate_pre_checks(self, changes: List[SchemaChange]) -> List[Dict[str, Any]]:
        """Generate pre-execution checks"""
        checks = []
        
        # Check for locked tables
        checks.append({
            'name': 'table_locks',
            'query': self.strategy.check_table_locks(),
            'expected': 0,
            'critical': True
        })
        
        # Check for running transactions
        checks.append({
            'name': 'long_running_transactions',
            'query': self.strategy.check_long_transactions(),
            'expected': 0,
            'critical': True
        })
        
        # Add change-specific checks
        for change in changes:
            if change.change_type == ChangeType.DROP_COLUMN:
                checks.append({
                    'name': f'column_usage_{change.table_name}_{change.details["column_name"]}',
                    'query': self.strategy.check_column_usage(
                        change.table_name, 
                        change.details["column_name"]
                    ),
                    'expected': 0,
                    'critical': False
                })
        
        return checks
    
    def _generate_post_checks(self, changes: List[SchemaChange]) -> List[Dict[str, Any]]:
        """Generate post-execution checks"""
        checks = []
        
        # Verify schema changes
        for change in changes:
            if change.change_type == ChangeType.CREATE_TABLE:
                checks.append({
                    'name': f'table_exists_{change.table_name}',
                    'query': f"SELECT 1 FROM information_schema.tables WHERE table_name = '{change.table_name}'",
                    'expected': 1,
                    'critical': True
                })
        
        return checks
    
    def _estimate_downtime(self, changes: List[SchemaChange]) -> float:
        """Estimate migration downtime in seconds"""
        total_time = 0.0
        
        for change in changes:
            # Rough estimates based on operation type
            if change.change_type == ChangeType.CREATE_TABLE:
                total_time += 0.1
            elif change.change_type == ChangeType.DROP_TABLE:
                total_time += 0.1
            elif change.change_type == ChangeType.ADD_COLUMN:
                # Depends on table size
                row_count = self._get_table_row_count(change.table_name)
                total_time += row_count / 100000  # 100k rows per second
            elif change.change_type == ChangeType.ADD_INDEX:
                row_count = self._get_table_row_count(change.table_name)
                total_time += row_count / 50000  # 50k rows per second for index
        
        return total_time
    
    def _calculate_risk_score(self, changes: List[SchemaChange]) -> int:
        """Calculate total risk score"""
        risk_scores = {'low': 1, 'medium': 5, 'high': 10}
        return sum(risk_scores[c.risk_level] for c in changes)
    
    def _run_pre_checks(self, checks: List[Dict[str, Any]]) -> bool:
        """Run pre-execution checks"""
        for check in checks:
            with self.engine.connect() as conn:
                result = conn.execute(sa.text(check['query']))
                value = result.scalar()
                
                if value != check['expected']:
                    print(f"Pre-check failed: {check['name']} (got {value}, expected {check['expected']})")
                    if check['critical']:
                        return False
        
        return True
    
    def _run_post_checks(self, checks: List[Dict[str, Any]]) -> bool:
        """Run post-execution checks"""
        for check in checks:
            with self.engine.connect() as conn:
                result = conn.execute(sa.text(check['query']))
                value = result.scalar()
                
                if value != check['expected']:
                    print(f"Post-check failed: {check['name']}")
                    if check['critical']:
                        return False
        
        return True

class DatabaseStrategy(ABC):
    """Abstract base class for database-specific operations"""
    
    @abstractmethod
    def generate_create_table(self, table: sa.Table) -> str:
        pass
    
    @abstractmethod
    def generate_drop_table(self, table: sa.Table) -> str:
        pass
    
    @abstractmethod
    def generate_add_column(self, table: sa.Table, column: sa.Column) -> str:
        pass
    
    @abstractmethod
    def generate_drop_column(self, table: sa.Table, column: sa.Column) -> str:
        pass
    
    @abstractmethod
    def check_table_locks(self) -> str:
        pass
    
    @abstractmethod
    def check_long_transactions(self) -> str:
        pass

class PostgreSQLStrategy(DatabaseStrategy):
    """PostgreSQL-specific operations"""
    
    def generate_create_table(self, table: sa.Table) -> str:
        # Generate CREATE TABLE statement
        ddl = sa.schema.CreateTable(table)
        return str(ddl.compile(compile_kwargs={"literal_binds": True}))
    
    def generate_drop_table(self, table: sa.Table) -> str:
        return f"DROP TABLE IF EXISTS {table.name} CASCADE"
    
    def generate_add_column(self, table: sa.Table, column: sa.Column) -> str:
        col_def = f"{column.name} {column.type}"
        if not column.nullable:
            col_def += " NOT NULL"
        if column.default is not None:
            col_def += f" DEFAULT {column.default}"
        
        return f"ALTER TABLE {table.name} ADD COLUMN {col_def}"
    
    def generate_drop_column(self, table: sa.Table, column: sa.Column) -> str:
        return f"ALTER TABLE {table.name} DROP COLUMN {column.name}"
    
    def check_table_locks(self) -> str:
        return """
        SELECT COUNT(*) 
        FROM pg_locks l
        JOIN pg_class c ON l.relation = c.oid
        WHERE c.relkind = 'r' AND l.mode = 'AccessExclusiveLock'
        """
    
    def check_long_transactions(self) -> str:
        return """
        SELECT COUNT(*)
        FROM pg_stat_activity
        WHERE state != 'idle' 
        AND query_start < NOW() - INTERVAL '5 minutes'
        """
    
    def check_column_usage(self, table_name: str, column_name: str) -> str:
        return f"""
        SELECT COUNT(*) 
        FROM {table_name} 
        WHERE {column_name} IS NOT NULL
        """

class MySQLStrategy(DatabaseStrategy):
    """MySQL-specific operations"""
    
    def generate_create_table(self, table: sa.Table) -> str:
        ddl = sa.schema.CreateTable(table)
        return str(ddl.compile(compile_kwargs={"literal_binds": True}))
    
    def generate_drop_table(self, table: sa.Table) -> str:
        return f"DROP TABLE IF EXISTS {table.name}"
    
    def generate_add_column(self, table: sa.Table, column: sa.Column) -> str:
        col_def = f"{column.name} {column.type}"
        if not column.nullable:
            col_def += " NOT NULL"
        if column.default is not None:
            col_def += f" DEFAULT {column.default}"
        
        return f"ALTER TABLE {table.name} ADD COLUMN {col_def}"
    
    def generate_drop_column(self, table: sa.Table, column: sa.Column) -> str:
        return f"ALTER TABLE {table.name} DROP COLUMN {column.name}"
    
    def check_table_locks(self) -> str:
        return """
        SELECT COUNT(*) 
        FROM information_schema.innodb_locks
        """
    
    def check_long_transactions(self) -> str:
        return """
        SELECT COUNT(*)
        FROM information_schema.processlist
        WHERE command != 'Sleep' AND time > 300
        """

class SQLiteStrategy(DatabaseStrategy):
    """SQLite-specific operations"""
    
    def generate_create_table(self, table: sa.Table) -> str:
        ddl = sa.schema.CreateTable(table)
        return str(ddl.compile(compile_kwargs={"literal_binds": True}))
    
    def generate_drop_table(self, table: sa.Table) -> str:
        return f"DROP TABLE IF EXISTS {table.name}"
    
    def generate_add_column(self, table: sa.Table, column: sa.Column) -> str:
        col_def = f"{column.name} {column.type}"
        if column.default is not None:
            col_def += f" DEFAULT {column.default}"
        
        return f"ALTER TABLE {table.name} ADD COLUMN {col_def}"
    
    def generate_drop_column(self, table: sa.Table, column: sa.Column) -> str:
        # SQLite doesn't support DROP COLUMN directly
        return f"-- SQLite doesn't support DROP COLUMN. Table recreation needed."
    
    def check_table_locks(self) -> str:
        # SQLite handles locks differently
        return "SELECT 0"
    
    def check_long_transactions(self) -> str:
        return "SELECT 0"

class GenericStrategy(DatabaseStrategy):
    """Generic fallback strategy"""
    
    def generate_create_table(self, table: sa.Table) -> str:
        return f"CREATE TABLE {table.name} (...)"
    
    def generate_drop_table(self, table: sa.Table) -> str:
        return f"DROP TABLE {table.name}"
    
    def generate_add_column(self, table: sa.Table, column: sa.Column) -> str:
        return f"ALTER TABLE {table.name} ADD COLUMN {column.name} {column.type}"
    
    def generate_drop_column(self, table: sa.Table, column: sa.Column) -> str:
        return f"ALTER TABLE {table.name} DROP COLUMN {column.name}"
    
    def check_table_locks(self) -> str:
        return "SELECT 0"
    
    def check_long_transactions(self) -> str:
        return "SELECT 0"
```

### Step 2: Implement Migration Safety Features

**Copilot Prompt Suggestion:**
```python
# Create safety features for migrations:
# - Data backup before migration
# - Progressive migration for large tables
# - Zero-downtime migration strategies
# - Automatic rollback on failure
# - Migration testing framework
```

Create `src/agents/migration_safety.py`:
```python
import os
import subprocess
from typing import Dict, Any, List, Optional
from datetime import datetime
import tempfile
import shutil

class MigrationSafetyManager:
    """Manages safety features for database migrations"""
    
    def __init__(self, agent: 'DatabaseMigrationAgent'):
        self.agent = agent
        self.backup_dir = tempfile.mkdtemp(prefix="migration_backup_")
        
    def create_backup(self, tables: List[str]) -> Dict[str, str]:
        """Create backup of specified tables"""
        backups = {}
        
        for table in tables:
            backup_file = os.path.join(self.backup_dir, f"{table}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.sql")
            
            if self.agent.dialect == 'postgresql':
                self._backup_postgresql_table(table, backup_file)
            elif self.agent.dialect == 'mysql':
                self._backup_mysql_table(table, backup_file)
            elif self.agent.dialect == 'sqlite':
                self._backup_sqlite_table(table, backup_file)
            
            backups[table] = backup_file
            
        return backups
    
    def restore_backup(self, backups: Dict[str, str]):
        """Restore tables from backup"""
        for table, backup_file in backups.items():
            if os.path.exists(backup_file):
                if self.agent.dialect == 'postgresql':
                    self._restore_postgresql_table(table, backup_file)
                elif self.agent.dialect == 'mysql':
                    self._restore_mysql_table(table, backup_file)
                elif self.agent.dialect == 'sqlite':
                    self._restore_sqlite_table(table, backup_file)
    
    def cleanup_backups(self):
        """Clean up backup directory"""
        if os.path.exists(self.backup_dir):
            shutil.rmtree(self.backup_dir)
    
    def _backup_postgresql_table(self, table: str, backup_file: str):
        """Backup PostgreSQL table"""
        # Extract connection info
        url = self.agent.engine.url
        cmd = [
            'pg_dump',
            '-h', url.host or 'localhost',
            '-p', str(url.port or 5432),
            '-U', url.username,
            '-d', url.database,
            '-t', table,
            '-f', backup_file,
            '--data-only',
            '--no-owner'
        ]
        
        env = os.environ.copy()
        if url.password:
            env['PGPASSWORD'] = url.password
            
        subprocess.run(cmd, env=env, check=True)
    
    def _restore_postgresql_table(self, table: str, backup_file: str):
        """Restore PostgreSQL table"""
        # First truncate the table
        with self.agent.engine.begin() as conn:
            conn.execute(sa.text(f"TRUNCATE TABLE {table} CASCADE"))
        
        # Then restore data
        url = self.agent.engine.url
        cmd = [
            'psql',
            '-h', url.host or 'localhost',
            '-p', str(url.port or 5432),
            '-U', url.username,
            '-d', url.database,
            '-f', backup_file
        ]
        
        env = os.environ.copy()
        if url.password:
            env['PGPASSWORD'] = url.password
            
        subprocess.run(cmd, env=env, check=True)

class ProgressiveMigration:
    """Handle progressive migrations for large tables"""
    
    def __init__(self, agent: 'DatabaseMigrationAgent'):
        self.agent = agent
        self.batch_size = 10000
        
    def migrate_in_batches(self, change: 'SchemaChange', 
                          progress_callback: Optional[callable] = None):
        """Migrate data in batches for large tables"""
        if change.change_type not in [ChangeType.ADD_COLUMN, ChangeType.ALTER_COLUMN]:
            # Regular migration for non-data changes
            return self.agent._execute_migration(change)
        
        # Get total rows
        total_rows = self.agent._get_table_row_count(change.table_name)
        
        if total_rows < self.batch_size:
            # Small table, regular migration
            return self.agent._execute_migration(change)
        
        # Large table, batch migration
        processed = 0
        
        while processed < total_rows:
            with self.agent.engine.begin() as conn:
                # Process batch
                batch_sql = self._create_batch_sql(change, processed, self.batch_size)
                conn.execute(sa.text(batch_sql))
                
                processed += self.batch_size
                
                if progress_callback:
                    progress_callback(processed, total_rows)
    
    def _create_batch_sql(self, change: 'SchemaChange', offset: int, limit: int) -> str:
        """Create SQL for batch processing"""
        # This is simplified - real implementation would be more complex
        if change.change_type == ChangeType.ADD_COLUMN:
            return f"""
            UPDATE {change.table_name}
            SET {change.details['column_name']} = {change.details['default_value']}
            WHERE ctid IN (
                SELECT ctid FROM {change.table_name}
                ORDER BY ctid
                LIMIT {limit} OFFSET {offset}
            )
            """
        return change.forward_sql

class ZeroDowntimeMigration:
    """Strategies for zero-downtime migrations"""
    
    def __init__(self, agent: 'DatabaseMigrationAgent'):
        self.agent = agent
        
    def add_column_with_default(self, table_name: str, column: sa.Column) -> List['SchemaChange']:
        """Add column with default value using zero-downtime strategy"""
        changes = []
        
        # Step 1: Add nullable column
        add_column = SchemaChange(
            change_type=ChangeType.ADD_COLUMN,
            table_name=table_name,
            details={'column_name': column.name, 'nullable': True},
            forward_sql=f"ALTER TABLE {table_name} ADD COLUMN {column.name} {column.type}",
            backward_sql=f"ALTER TABLE {table_name} DROP COLUMN {column.name}",
            risk_level="low"
        )
        changes.append(add_column)
        
        # Step 2: Backfill in batches
        backfill = SchemaChange(
            change_type=ChangeType.ALTER_COLUMN,
            table_name=table_name,
            details={'column_name': column.name, 'operation': 'backfill'},
            forward_sql=f"UPDATE {table_name} SET {column.name} = {column.default} WHERE {column.name} IS NULL",
            backward_sql=None,
            risk_level="medium"
        )
        changes.append(backfill)
        
        # Step 3: Add NOT NULL constraint
        if not column.nullable:
            add_constraint = SchemaChange(
                change_type=ChangeType.ADD_CONSTRAINT,
                table_name=table_name,
                details={'constraint_type': 'NOT NULL', 'column_name': column.name},
                forward_sql=f"ALTER TABLE {table_name} ALTER COLUMN {column.name} SET NOT NULL",
                backward_sql=f"ALTER TABLE {table_name} ALTER COLUMN {column.name} DROP NOT NULL",
                risk_level="low"
            )
            changes.append(add_constraint)
        
        return changes
    
    def rename_column_safely(self, table_name: str, old_name: str, new_name: str) -> List['SchemaChange']:
        """Rename column with backward compatibility"""
        changes = []
        
        # Step 1: Add new column as copy
        add_column = SchemaChange(
            change_type=ChangeType.ADD_COLUMN,
            table_name=table_name,
            details={'column_name': new_name, 'copy_from': old_name},
            forward_sql=f"ALTER TABLE {table_name} ADD COLUMN {new_name} AS ({old_name}) STORED",
            backward_sql=f"ALTER TABLE {table_name} DROP COLUMN {new_name}",
            risk_level="low"
        )
        changes.append(add_column)
        
        # Step 2: Create trigger to sync changes (PostgreSQL example)
        if self.agent.dialect == 'postgresql':
            trigger_sql = f"""
            CREATE OR REPLACE FUNCTION sync_{table_name}_{old_name}_to_{new_name}()
            RETURNS TRIGGER AS $$
            BEGIN
                NEW.{new_name} := NEW.{old_name};
                RETURN NEW;
            END;
            $$ LANGUAGE plpgsql;
            
            CREATE TRIGGER {table_name}_{old_name}_sync
            BEFORE INSERT OR UPDATE ON {table_name}
            FOR EACH ROW EXECUTE FUNCTION sync_{table_name}_{old_name}_to_{new_name}();
            """
            
            create_trigger = SchemaChange(
                change_type=ChangeType.ADD_CONSTRAINT,
                table_name=table_name,
                details={'constraint_type': 'TRIGGER', 'name': f'{table_name}_{old_name}_sync'},
                forward_sql=trigger_sql,
                backward_sql=f"DROP TRIGGER IF EXISTS {table_name}_{old_name}_sync ON {table_name}",
                risk_level="medium"
            )
            changes.append(create_trigger)
        
        return changes
```

### Step 3: Create Migration Testing Framework

Create `src/testing/migration_test.py`:
```python
import pytest
from typing import Dict, Any, List
import sqlalchemy as sa
from sqlalchemy import MetaData, Table, Column, Integer, String, DateTime

class MigrationTestFramework:
    """Framework for testing migrations"""
    
    def __init__(self, agent: 'DatabaseMigrationAgent'):
        self.agent = agent
        self.test_metadata = MetaData()
        
    def create_test_schema(self) -> MetaData:
        """Create test schema for migration testing"""
        # Create sample tables
        users_table = Table(
            'users',
            self.test_metadata,
            Column('id', Integer, primary_key=True),
            Column('username', String(50), nullable=False),
            Column('email', String(100), nullable=False),
            Column('created_at', DateTime, nullable=False)
        )
        
        posts_table = Table(
            'posts',
            self.test_metadata,
            Column('id', Integer, primary_key=True),
            Column('user_id', Integer, sa.ForeignKey('users.id')),
            Column('title', String(200), nullable=False),
            Column('content', sa.Text),
            Column('published_at', DateTime)
        )
        
        return self.test_metadata
    
    def test_migration_forward_backward(self, migration: 'Migration'):
        """Test migration can go forward and backward"""
        # Take snapshot
        initial_schema = self._snapshot_schema()
        
        # Execute forward
        self.agent._execute_migration(migration)
        forward_schema = self._snapshot_schema()
        
        # Execute backward
        self.agent._rollback_migrations([migration.id])
        backward_schema = self._snapshot_schema()
        
        # Compare schemas
        assert initial_schema == backward_schema, "Backward migration didn't restore original schema"
        assert initial_schema != forward_schema, "Forward migration didn't change schema"
    
    def test_data_integrity(self, migration: 'Migration', test_data: Dict[str, List[Dict]]):
        """Test data integrity is maintained during migration"""
        # Insert test data
        self._insert_test_data(test_data)
        
        # Get data snapshot
        initial_data = self._snapshot_data(test_data.keys())
        
        # Execute migration
        self.agent._execute_migration(migration)
        
        # Verify data
        final_data = self._snapshot_data(test_data.keys())
        
        # Check critical data preserved
        for table in test_data.keys():
            assert len(initial_data[table]) == len(final_data[table]), f"Row count changed in {table}"
    
    def test_concurrent_access(self, migration: 'Migration'):
        """Test migration with concurrent database access"""
        import threading
        import time
        
        # Start concurrent queries
        stop_flag = threading.Event()
        errors = []
        
        def concurrent_queries():
            while not stop_flag.is_set():
                try:
                    with self.agent.engine.connect() as conn:
                        # Run sample queries
                        conn.execute(sa.text("SELECT 1"))
                        time.sleep(0.1)
                except Exception as e:
                    errors.append(e)
        
        # Start background thread
        thread = threading.Thread(target=concurrent_queries)
        thread.start()
        
        try:
            # Execute migration
            self.agent._execute_migration(migration)
        finally:
            # Stop background queries
            stop_flag.set()
            thread.join()
        
        # Check for errors
        assert len(errors) == 0, f"Concurrent access errors: {errors}"
    
    def _snapshot_schema(self) -> Dict[str, Any]:
        """Take snapshot of current schema"""
        metadata = MetaData()
        metadata.reflect(bind=self.agent.engine)
        
        snapshot = {}
        for table_name, table in metadata.tables.items():
            snapshot[table_name] = {
                'columns': {col.name: str(col.type) for col in table.columns},
                'indexes': [idx.name for idx in table.indexes],
                'constraints': [const.name for const in table.constraints]
            }
        
        return snapshot
    
    def _snapshot_data(self, tables: List[str]) -> Dict[str, List[Dict]]:
        """Take snapshot of data in tables"""
        snapshot = {}
        
        with self.agent.engine.connect() as conn:
            for table in tables:
                result = conn.execute(sa.text(f"SELECT * FROM {table}"))
                snapshot[table] = [dict(row) for row in result]
        
        return snapshot
    
    def _insert_test_data(self, test_data: Dict[str, List[Dict]]):
        """Insert test data into tables"""
        with self.agent.engine.begin() as conn:
            for table_name, rows in test_data.items():
                table = sa.Table(table_name, MetaData(), autoload_with=self.agent.engine)
                conn.execute(table.insert(), rows)
```

### Step 4: Create Demo and Integration

Create `src/migration_demo.py`:
```python
"""Demo script for database migration agent"""

from datetime import datetime
import sqlalchemy as sa
from sqlalchemy import MetaData, Table, Column, Integer, String, Boolean, DateTime, ForeignKey
from src.agents.migration_agent import DatabaseMigrationAgent
from src.agents.migration_safety import MigrationSafetyManager, ZeroDowntimeMigration

def create_initial_schema() -> MetaData:
    """Create initial database schema"""
    metadata = MetaData()
    
    # Users table
    Table(
        'users',
        metadata,
        Column('id', Integer, primary_key=True),
        Column('username', String(50), nullable=False),
        Column('email', String(100), nullable=False),
        Column('created_at', DateTime, default=datetime.now)
    )
    
    # Posts table
    Table(
        'posts',
        metadata,
        Column('id', Integer, primary_key=True),
        Column('user_id', Integer, ForeignKey('users.id')),
        Column('title', String(200), nullable=False),
        Column('content', sa.Text),
        Column('created_at', DateTime, default=datetime.now)
    )
    
    return metadata

def create_target_schema() -> MetaData:
    """Create target database schema with changes"""
    metadata = MetaData()
    
    # Users table - added 'active' column, 'last_login'
    Table(
        'users',
        metadata,
        Column('id', Integer, primary_key=True),
        Column('username', String(50), nullable=False),
        Column('email', String(100), nullable=False),
        Column('active', Boolean, default=True, nullable=False),  # New column
        Column('last_login', DateTime),  # New column
        Column('created_at', DateTime, default=datetime.now)
    )
    
    # Posts table - added 'published' column, 'view_count'
    Table(
        'posts',
        metadata,
        Column('id', Integer, primary_key=True),
        Column('user_id', Integer, ForeignKey('users.id')),
        Column('title', String(200), nullable=False),
        Column('content', sa.Text),
        Column('published', Boolean, default=False, nullable=False),  # New column
        Column('view_count', Integer, default=0, nullable=False),  # New column
        Column('created_at', DateTime, default=datetime.now),
        Column('updated_at', DateTime, default=datetime.now, onupdate=datetime.now)  # New column
    )
    
    # New table - comments
    Table(
        'comments',
        metadata,
        Column('id', Integer, primary_key=True),
        Column('post_id', Integer, ForeignKey('posts.id')),
        Column('user_id', Integer, ForeignKey('users.id')),
        Column('content', sa.Text, nullable=False),
        Column('created_at', DateTime, default=datetime.now)
    )
    
    return metadata

def main():
    """Run migration agent demo"""
    
    # Database connection (using SQLite for demo)
    connection_string = "sqlite:///migration_demo.db"
    
    # Create agent
    agent = DatabaseMigrationAgent(connection_string)
    
    # Create initial schema
    print("📊 Creating initial schema...")
    initial_metadata = create_initial_schema()
    initial_metadata.create_all(agent.engine)
    
    # Insert sample data
    print("📝 Inserting sample data...")
    with agent.engine.begin() as conn:
        # Insert users
        conn.execute(sa.text("""
            INSERT INTO users (username, email) VALUES
            ('john_doe', 'john@example.com'),
            ('jane_smith', 'jane@example.com'),
            ('bob_wilson', 'bob@example.com')
        """))
        
        # Insert posts
        conn.execute(sa.text("""
            INSERT INTO posts (user_id, title, content) VALUES
            (1, 'First Post', 'This is my first post'),
            (1, 'Second Post', 'Another post by John'),
            (2, 'Jane''s Post', 'Hello from Jane')
        """))
    
    # Analyze changes needed
    print("\n🔍 Analyzing schema differences...")
    target_metadata = create_target_schema()
    changes = agent.analyze_schema_diff(target_metadata)
    
    print(f"\nFound {len(changes)} schema changes:")
    for change in changes:
        print(f"  - {change.change_type.value}: {change.table_name}")
        if change.change_type in [ChangeType.ADD_COLUMN, ChangeType.DROP_COLUMN]:
            print(f"    Column: {change.details.get('column_name', 'N/A')}")
    
    # Create migration plan
    print("\n📋 Creating migration plan...")
    plan = agent.create_migration_plan(changes, name="add_features")
    
    print(f"\nMigration plan created:")
    print(f"  - Migrations: {len(plan.migrations)}")
    print(f"  - Estimated downtime: {plan.estimated_downtime:.2f} seconds")
    print(f"  - Risk score: {plan.total_risk_score}")
    
    # Safety features
    safety_manager = MigrationSafetyManager(agent)
    zero_downtime = ZeroDowntimeMigration(agent)
    
    # Create backups
    print("\n💾 Creating backups...")
    affected_tables = list(set(c.table_name for c in changes))
    backups = safety_manager.create_backup(affected_tables)
    print(f"Backed up {len(backups)} tables")
    
    # Execute dry run
    print("\n🧪 Executing dry run...")
    dry_run_result = agent.execute_migration_plan(plan, dry_run=True)
    
    if dry_run_result['success']:
        print("✅ Dry run successful!")
        
        # Execute actual migration
        print("\n🚀 Executing migration...")
        result = agent.execute_migration_plan(plan)
        
        if result['success']:
            print("✅ Migration completed successfully!")
            print(f"  - Execution time: {result['execution_time']:.2f} seconds")
            print(f"  - Migrations executed: {len(result['executed_migrations'])}")
            
            # Verify final schema
            print("\n🔍 Verifying final schema...")
            final_metadata = agent._get_current_metadata()
            
            print("Tables in database:")
            for table_name in sorted(final_metadata.tables.keys()):
                table = final_metadata.tables[table_name]
                print(f"  - {table_name}: {len(table.columns)} columns")
                
        else:
            print(f"❌ Migration failed: {result['error']}")
            if result['rollback_performed']:
                print("✅ Rollback completed successfully")
    else:
        print(f"❌ Dry run failed: {dry_run_result['error']}")
    
    # Cleanup
    safety_manager.cleanup_backups()
    
    # Show migration history
    print("\n📜 Migration History:")
    with agent.engine.connect() as conn:
        result = conn.execute(sa.text("""
            SELECT id, name, status, executed_at, execution_time
            FROM migration_history
            ORDER BY executed_at DESC
        """))
        
        for row in result:
            print(f"  - {row.name}: {row.status} ({row.execution_time:.2f}s)")

if __name__ == "__main__":
    main()
```

## 🏃 Running the Migration Agent

1. **Basic Usage**:
```python
from src.agents.migration_agent import DatabaseMigrationAgent

# Create agent
agent = DatabaseMigrationAgent("postgresql://user:pass@localhost/mydb")

# Analyze changes
changes = agent.analyze_schema_diff(target_metadata)

# Create and execute plan
plan = agent.create_migration_plan(changes)
result = agent.execute_migration_plan(plan)
```

2. **Zero-Downtime Migration**:
```python
from src.agents.migration_safety import ZeroDowntimeMigration

zero_dt = ZeroDowntimeMigration(agent)

# Add column with zero downtime
changes = zero_dt.add_column_with_default(
    'users',
    sa.Column('score', sa.Integer, default=0, nullable=False)
)

plan = agent.create_migration_plan(changes)
agent.execute_migration_plan(plan)
```

## 🎯 Validation

Run the validation script:
```bash
python scripts/validate_exercise2.py
```

Expected output:
```
✅ Migration agent implemented
✅ Schema analysis working
✅ Migration plan generation correct
✅ Safety features functional
✅ Rollback mechanism works
✅ Multi-database support verified

Score: 100/100
```

## 🚀 Extension Challenges

1. **Online Schema Change**: Implement pt-online-schema-change strategy
2. **Migration Scheduling**: Add time-based migration execution
3. **Conflict Resolution**: Handle concurrent schema modifications
4. **Data Transformation**: Complex data migrations during schema change
5. **Performance Monitoring**: Track migration impact on database performance

## 📚 Additional Resources

- [Flyway Documentation](https://flywaydb.org/)
- [Alembic Tutorial](https://alembic.sqlalchemy.org/)
- [Zero-Downtime Migrations](https://www.braintreepayments.com/blog/safe-operations-for-high-volume-postgresql/)
- [Database Refactoring](https://databaserefactoring.com/)

## ⏭️ Next Exercise

Ready for the final challenge? Move on to [Exercise 3: Architecture Decision Agent](../exercise3-hard/README.md)!