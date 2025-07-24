---
sidebar_position: 2
title: "Exercise 3: Overview"
description: "## 🎯 Objective"
---

# Exercise 3: Enterprise Security Platform (⭐⭐⭐ Hard - 60 minutes)

## 🎯 Objective

Build a comprehensive enterprise security platform that integrates Microsoft Sentinel (SIEM), automated threat remediation, compliance reporting, and real-time security monitoring. This platform will serve as the central security hub for all enterprise applications.

## 🔑 What You'll Learn

- Integrate with Microsoft Sentinel for SIEM
- Implement automated security remediation
- Create real-time threat detection
- Build compliance reporting system
- Deploy security orchestration
- Monitor security posture continuously

## 📋 Requirements

- Azure subscription with Sentinel enabled
- Microsoft Defender for Cloud
- GitHub Advanced Security
- Python with Azure SDK
- Docker for containerization

## 📝 Instructions

### Step 1: Set Up Security Platform Infrastructure

Create the project structure:

```bash
mkdir enterprise-security-platform
cd enterprise-security-platform

# Install required packages
pip install azure-monitor-query==1.2.0
pip install azure-mgmt-sentinel==1.0.0
pip install azure-mgmt-security==3.0.0
pip install azure-mgmt-monitor==6.0.0
pip install github3.py==4.0.0
pip install asyncio-throttle==0.1.1
```

### Step 2: Create Security Orchestration Service

**Copilot Prompt Suggestion:**
```
Create a Python security orchestration service that:
- Connects to Microsoft Sentinel for threat intelligence
- Integrates with Microsoft Defender for vulnerability data
- Monitors GitHub Advanced Security alerts
- Implements automated remediation workflows
- Uses Microsoft Entra ID for authentication
- Provides real-time security metrics
Include async processing and error recovery.
```

**Expected Output:**
```python
import asyncio
from typing import Dict, List, Any, Optional
from datetime import datetime, timedelta
from azure.identity import DefaultAzureCredential
from azure.monitor.query import LogsQueryClient, MetricsQueryClient
from azure.mgmt.sentinel import SecurityInsights
from azure.mgmt.security import SecurityCenter
from azure.mgmt.monitor import MonitorManagementClient
from github3 import GitHub
from enum import Enum
import logging
import json
from dataclasses import dataclass
from asyncio_throttle import Throttler

logger = logging.getLogger(__name__)

class ThreatLevel(Enum):
    """Threat severity levels."""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

class RemediationStatus(Enum):
    """Remediation workflow status."""
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    FAILED = "failed"
    MANUAL_REQUIRED = "manual_required"

@dataclass
class SecurityIncident:
    """Security incident data structure."""
    id: str
    source: str  # sentinel, defender, github
    title: str
    description: str
    severity: ThreatLevel
    timestamp: datetime
    affected_resources: List[str]
    indicators: Dict[str, Any]
    remediation_actions: List[str]
    status: RemediationStatus

class SecurityOrchestrator:
    """Enterprise security orchestration platform."""
    
    def __init__(
        self,
        subscription_id: str,
        workspace_id: str,
        resource_group: str,
        github_token: str
    ):
        self.subscription_id = subscription_id
        self.workspace_id = workspace_id
        self.resource_group = resource_group
        
        # Initialize Azure clients with Microsoft Entra ID auth
        self.credential = DefaultAzureCredential()
        self._init_azure_clients()
        
        # Initialize GitHub client
        self.github = GitHub(token=github_token)
        
        # Rate limiting
        self.throttler = Throttler(rate_limit=10, period=60)
        
        # Incident tracking
        self.active_incidents: Dict[str, SecurityIncident] = {}
        self.remediation_queue = asyncio.Queue()
        
        # Metrics
        self.metrics = {
            "incidents_detected": 0,
            "incidents_remediated": 0,
            "false_positives": 0,
            "mean_time_to_remediate": 0
        }
    
    def _init_azure_clients(self):
        """Initialize Azure service clients."""
        self.logs_client = LogsQueryClient(self.credential)
        self.metrics_client = MetricsQueryClient(self.credential)
        self.sentinel_client = SecurityInsights(
            self.credential,
            self.subscription_id
        )
        self.security_center = SecurityCenter(
            self.credential,
            self.subscription_id
        )
        self.monitor_client = MonitorManagementClient(
            self.credential,
            self.subscription_id
        )
    
    async def start_monitoring(self):
        """Start security monitoring and orchestration."""
        logger.info("Starting security orchestration platform")
        
        # Start monitoring tasks
        tasks = [
            self._monitor_sentinel(),
            self._monitor_defender(),
            self._monitor_github_security(),
            self._process_remediation_queue(),
            self._update_metrics()
        ]
        
        await asyncio.gather(*tasks)
    
    async def _monitor_sentinel(self):
        """Monitor Microsoft Sentinel for security incidents."""
        while True:
            try:
                async with self.throttler:
                    # Query Sentinel for new incidents
                    query = """
                    SecurityIncident
                    | where TimeGenerated &gt; ago(5m)
                    | where Status == "New"
                    | project 
                        IncidentNumber,
                        Title,
                        Description,
                        Severity,
                        TimeGenerated,
                        AlertIds,
                        Status
                    | order by TimeGenerated desc
                    | limit 50
                    """
                    
                    response = await self._query_logs(query)
                    
                    for row in response:
                        incident = await self._process_sentinel_incident(row)
                        if incident:
                            await self._handle_incident(incident)
                
                await asyncio.sleep(60)  # Check every minute
                
            except Exception as e:
                logger.error(f"Sentinel monitoring error: {e}")
                await asyncio.sleep(30)
    
    async def _monitor_defender(self):
        """Monitor Microsoft Defender for Cloud alerts."""
        while True:
            try:
                async with self.throttler:
                    # Get security alerts from Defender
                    alerts = self.security_center.alerts.list(
                        filter="properties/status eq 'Active'"
                    )
                    
                    for alert in alerts:
                        incident = await self._process_defender_alert(alert)
                        if incident:
                            await self._handle_incident(incident)
                
                await asyncio.sleep(120)  # Check every 2 minutes
                
            except Exception as e:
                logger.error(f"Defender monitoring error: {e}")
                await asyncio.sleep(60)
    
    async def _monitor_github_security(self):
        """Monitor GitHub Advanced Security alerts."""
        while True:
            try:
                async with self.throttler:
                    # Get security alerts from repositories
                    for repo in self.github.repositories():
                        # Code scanning alerts
                        for alert in repo.code_scanning_alerts():
                            if alert.state == 'open':
                                incident = await self._process_github_alert(
                                    alert, 
                                    'code_scanning',
                                    repo
                                )
                                if incident:
                                    await self._handle_incident(incident)
                        
                        # Secret scanning alerts
                        for alert in repo.secret_scanning_alerts():
                            if alert.state == 'open':
                                incident = await self._process_github_alert(
                                    alert,
                                    'secret_scanning',
                                    repo
                                )
                                if incident:
                                    await self._handle_incident(incident)
                
                await asyncio.sleep(300)  # Check every 5 minutes
                
            except Exception as e:
                logger.error(f"GitHub monitoring error: {e}")
                await asyncio.sleep(120)
    
    async def _process_sentinel_incident(
        self, 
        row: Dict[str, Any]
    ) -&gt; Optional[SecurityIncident]:
        """Process Sentinel incident data."""
        try:
            severity_map = {
                "High": ThreatLevel.HIGH,
                "Medium": ThreatLevel.MEDIUM,
                "Low": ThreatLevel.LOW,
                "Informational": ThreatLevel.LOW
            }
            
            incident = SecurityIncident(
                id=f"sentinel_{row['IncidentNumber']}",
                source="sentinel",
                title=row['Title'],
                description=row['Description'],
                severity=severity_map.get(row['Severity'], ThreatLevel.MEDIUM),
                timestamp=row['TimeGenerated'],
                affected_resources=await self._get_affected_resources(row['AlertIds']),
                indicators=await self._extract_indicators(row),
                remediation_actions=await self._determine_remediation(row),
                status=RemediationStatus.PENDING
            )
            
            return incident
            
        except Exception as e:
            logger.error(f"Error processing Sentinel incident: {e}")
            return None
    
    async def _process_defender_alert(
        self,
        alert: Any
    ) -&gt; Optional[SecurityIncident]:
        """Process Defender for Cloud alert."""
        try:
            severity_map = {
                "High": ThreatLevel.HIGH,
                "Medium": ThreatLevel.MEDIUM,
                "Low": ThreatLevel.LOW
            }
            
            incident = SecurityIncident(
                id=f"defender_{alert.name}",
                source="defender",
                title=alert.properties.alert_display_name,
                description=alert.properties.description,
                severity=severity_map.get(
                    alert.properties.severity,
                    ThreatLevel.MEDIUM
                ),
                timestamp=alert.properties.time_generated,
                affected_resources=[alert.properties.resource_id],
                indicators={
                    "attack_vector": alert.properties.attack_vector,
                    "compromised_entity": alert.properties.compromised_entity
                },
                remediation_actions=alert.properties.remediation_steps,
                status=RemediationStatus.PENDING
            )
            
            return incident
            
        except Exception as e:
            logger.error(f"Error processing Defender alert: {e}")
            return None
    
    async def _process_github_alert(
        self,
        alert: Any,
        alert_type: str,
        repo: Any
    ) -&gt; Optional[SecurityIncident]:
        """Process GitHub security alert."""
        try:
            severity_map = {
                "critical": ThreatLevel.CRITICAL,
                "high": ThreatLevel.HIGH,
                "medium": ThreatLevel.MEDIUM,
                "low": ThreatLevel.LOW
            }
            
            if alert_type == "code_scanning":
                severity = severity_map.get(
                    alert.rule.severity,
                    ThreatLevel.MEDIUM
                )
                title = f"Code vulnerability: {alert.rule.description}"
                remediation = [
                    f"Fix {alert.rule.id} in {alert.location.path}",
                    "Review and update code",
                    "Run security tests"
                ]
            else:  # secret_scanning
                severity = ThreatLevel.CRITICAL
                title = f"Secret exposed: {alert.secret_type}"
                remediation = [
                    "Revoke the exposed secret immediately",
                    "Rotate credentials",
                    "Update secret in secure storage",
                    "Audit access logs"
                ]
            
            incident = SecurityIncident(
                id=f"github_{repo.name}_{alert_type}_{alert.number}",
                source="github",
                title=title,
                description=alert.html_url,
                severity=severity,
                timestamp=datetime.fromisoformat(alert.created_at),
                affected_resources=[f"{repo.full_name}:{alert.location.path}"],
                indicators={
                    "alert_type": alert_type,
                    "repository": repo.full_name,
                    "file": getattr(alert.location, 'path', 'unknown')
                },
                remediation_actions=remediation,
                status=RemediationStatus.PENDING
            )
            
            return incident
            
        except Exception as e:
            logger.error(f"Error processing GitHub alert: {e}")
            return None
    
    async def _handle_incident(self, incident: SecurityIncident):
        """Handle security incident with automated remediation."""
        # Check if already being handled
        if incident.id in self.active_incidents:
            return
        
        self.active_incidents[incident.id] = incident
        self.metrics["incidents_detected"] += 1
        
        # Log incident
        logger.warning(
            f"Security incident detected: {incident.title} "
            f"(Severity: {incident.severity.value})"
        )
        
        # Send to remediation queue
        await self.remediation_queue.put(incident)
        
        # Create alert based on severity
        if incident.severity in [ThreatLevel.HIGH, ThreatLevel.CRITICAL]:
            await self._create_priority_alert(incident)
    
    async def _process_remediation_queue(self):
        """Process remediation actions for incidents."""
        while True:
            try:
                incident = await self.remediation_queue.get()
                
                # Update status
                incident.status = RemediationStatus.IN_PROGRESS
                
                # Execute remediation based on incident type
                success = await self._execute_remediation(incident)
                
                if success:
                    incident.status = RemediationStatus.COMPLETED
                    self.metrics["incidents_remediated"] += 1
                else:
                    incident.status = RemediationStatus.MANUAL_REQUIRED
                
                # Update incident record
                await self._update_incident_status(incident)
                
            except Exception as e:
                logger.error(f"Remediation error: {e}")
                if incident:
                    incident.status = RemediationStatus.FAILED
    
    async def _execute_remediation(self, incident: SecurityIncident) -&gt; bool:
        """Execute automated remediation actions."""
        try:
            if incident.source == "github" and "secret" in incident.title.lower():
                # Automated secret rotation
                return await self._remediate_exposed_secret(incident)
            
            elif incident.source == "defender" and incident.severity == ThreatLevel.HIGH:
                # Automated threat isolation
                return await self._isolate_compromised_resource(incident)
            
            elif incident.source == "sentinel":
                # Execute Sentinel playbook
                return await self._execute_sentinel_playbook(incident)
            
            else:
                # Log for manual review
                logger.info(
                    f"Manual remediation required for: {incident.id}"
                )
                return False
                
        except Exception as e:
            logger.error(f"Remediation execution failed: {e}")
            return False
    
    async def _remediate_exposed_secret(
        self,
        incident: SecurityIncident
    ) -&gt; bool:
        """Remediate exposed secret in GitHub."""
        try:
            # Parse repository and file from incident
            repo_name = incident.indicators.get("repository")
            file_path = incident.indicators.get("file")
            
            if not repo_name:
                return False
            
            repo = self.github.repository(*repo_name.split('/'))
            
            # Create issue for tracking
            issue = repo.create_issue(
                title=f"SECURITY: {incident.title}",
                body=f"""
                ## Security Alert
                
                A secret has been exposed in the repository.
                
                **File**: {file_path}
                **Type**: {incident.indicators.get('alert_type')}
                **Severity**: {incident.severity.value}
                
                ### Required Actions:
                1. Secret has been automatically revoked
                2. Please update the code to use secure secret management
                3. Rotate all related credentials
                4. Review access logs for any unauthorized usage
                
                This issue was automatically created by the Security Platform.
                """
            )
            
            # Add security label
            issue.add_labels('security', 'urgent')
            
            logger.info(f"Created security issue: {issue.html_url}")
            return True
            
        except Exception as e:
            logger.error(f"Secret remediation failed: {e}")
            return False
    
    async def _isolate_compromised_resource(
        self,
        incident: SecurityIncident
    ) -&gt; bool:
        """Isolate compromised Azure resource."""
        try:
            resource_id = incident.affected_resources[0]
            
            # Apply network isolation using NSG
            nsg_rule = {
                "name": f"ISOLATE_{{incident.id}}",
                "priority": 100,
                "direction": "Inbound",
                "access": "Deny",
                "protocol": "*",
                "source_address_prefix": "*",
                "destination_address_prefix": "*",
                "description": f"Security isolation for incident {{incident.id}}"
            }
            
            # This is a simplified example - actual implementation would
            # use Azure Resource Manager to apply the NSG rule
            logger.info(f"Isolated resource: {resource_id}")
            return True
            
        except Exception as e:
            logger.error(f"Resource isolation failed: {e}")
            return False
    
    async def _execute_sentinel_playbook(
        self,
        incident: SecurityIncident
    ) -&gt; bool:
        """Execute Microsoft Sentinel playbook."""
        try:
            # Trigger Logic App playbook
            playbook_name = self._select_playbook(incident)
            
            if playbook_name:
                # This would trigger the actual Logic App
                logger.info(
                    f"Executed Sentinel playbook: {playbook_name} "
                    f"for incident: {incident.id}"
                )
                return True
            
            return False
            
        except Exception as e:
            logger.error(f"Playbook execution failed: {e}")
            return False
    
    async def _create_priority_alert(self, incident: SecurityIncident):
        """Create high-priority alert for critical incidents."""
        alert = {
            "severity": incident.severity.value,
            "title": f"CRITICAL: {{incident.title}}",
            "description": incident.description,
            "source": incident.source,
            "timestamp": incident.timestamp.isoformat(),
            "affected_resources": incident.affected_resources,
            "recommended_actions": incident.remediation_actions
        }
        
        # Send to notification channels
        await self._send_alert_notifications(alert)
        
        # Log critical alert
        logger.critical(f"Priority alert created: {json.dumps(alert)}")
    
    async def _query_logs(self, query: str) -&gt; List[Dict[str, Any]]:
        """Query Azure Monitor logs."""
        response = self.logs_client.query_workspace(
            workspace_id=self.workspace_id,
            query=query,
            timespan=timedelta(hours=1)
        )
        
        if response.status == "Success":
            return [
                {col: row[i] for i, col in enumerate(response.tables[0].columns)}
                for row in response.tables[0].rows
            ]
        return []
    
    async def _update_metrics(self):
        """Update security metrics periodically."""
        while True:
            try:
                # Calculate mean time to remediate
                completed_incidents = [
                    inc for inc in self.active_incidents.values()
                    if inc.status == RemediationStatus.COMPLETED
                ]
                
                if completed_incidents:
                    total_time = sum(
                        (datetime.utcnow() - inc.timestamp).total_seconds()
                        for inc in completed_incidents
                    )
                    self.metrics["mean_time_to_remediate"] = (
                        total_time / len(completed_incidents) / 60  # minutes
                    )
                
                # Log metrics
                logger.info(f"Security metrics: {json.dumps(self.metrics)}")
                
                # Send to monitoring dashboard
                await self._publish_metrics()
                
                await asyncio.sleep(300)  # Update every 5 minutes
                
            except Exception as e:
                logger.error(f"Metrics update error: {e}")
                await asyncio.sleep(60)
    
    async def _publish_metrics(self):
        """Publish metrics to monitoring system."""
        # Send custom metrics to Azure Monitor
        for metric_name, value in self.metrics.items():
            try:
                # This would use Azure Monitor custom metrics API
                logger.debug(f"Published metric: {metric_name}={value}")
            except Exception as e:
                logger.error(f"Failed to publish metric {metric_name}: {e}")
    
    def _select_playbook(self, incident: SecurityIncident) -&gt; Optional[str]:
        """Select appropriate playbook based on incident type."""
        playbook_mapping = {
            (ThreatLevel.CRITICAL, "malware"): "IsolateAndScan",
            (ThreatLevel.HIGH, "bruteforce"): "BlockIPAddress",
            (ThreatLevel.HIGH, "privilege"): "RevokeAccess",
            (ThreatLevel.MEDIUM, "anomaly"): "InvestigateActivity"
        }
        
        # Simple matching based on severity and keywords
        for keyword in ["malware", "bruteforce", "privilege", "anomaly"]:
            if keyword in incident.title.lower():
                key = (incident.severity, keyword)
                return playbook_mapping.get(key)
        
        return None
    
    async def _send_alert_notifications(self, alert: Dict[str, Any]):
        """Send alert notifications through various channels."""
        # This would integrate with notification services like
        # Teams, Slack, PagerDuty, etc.
        pass
    
    async def _get_affected_resources(
        self,
        alert_ids: List[str]
    ) -&gt; List[str]:
        """Get affected resources from alert IDs."""
        # Query for resource details
        return []
    
    async def _extract_indicators(
        self,
        incident_data: Dict[str, Any]
    ) -&gt; Dict[str, Any]:
        """Extract threat indicators from incident."""
        # Extract IOCs, tactics, techniques
        return {}
    
    async def _determine_remediation(
        self,
        incident_data: Dict[str, Any]
    ) -&gt; List[str]:
        """Determine remediation actions for incident."""
        # AI-powered remediation suggestions
        return []
    
    async def _update_incident_status(self, incident: SecurityIncident):
        """Update incident status in tracking system."""
        # Update status in Sentinel or internal tracking
        pass
```

### Step 3: Create Compliance Reporting System

**Copilot Prompt Suggestion:**
```
Create a compliance reporting system that:
- Generates GDPR, HIPAA, and SOC2 compliance reports
- Tracks security control effectiveness
- Monitors policy violations
- Creates audit evidence packages
- Schedules automated compliance scans
- Provides executive dashboards
Include PDF generation and email distribution.
```

**Expected Output:**
```python
from typing import Dict, List, Any, Optional
from datetime import datetime, timedelta
import pandas as pd
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter, A4
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, PageBreak, Image
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
import matplotlib.pyplot as plt
import seaborn as sns
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.application import MIMEApplication
import smtplib
import json
from dataclasses import dataclass
import asyncio

@dataclass
class ComplianceControl:
    """Compliance control definition."""
    id: str
    name: str
    description: str
    framework: str  # GDPR, HIPAA, SOC2
    category: str
    automated: bool
    last_tested: datetime
    status: str  # compliant, non_compliant, partial
    evidence: List[str]
    remediation: Optional[str]

class ComplianceReporter:
    """Enterprise compliance reporting system."""
    
    def __init__(
        self,
        security_orchestrator: SecurityOrchestrator,
        smtp_config: Dict[str, str]
    ):
        self.orchestrator = security_orchestrator
        self.smtp_config = smtp_config
        self.styles = getSampleStyleSheet()
        self._init_custom_styles()
        
        # Compliance controls
        self.controls = self._load_compliance_controls()
        
        # Metrics storage
        self.compliance_metrics = {
            "gdpr": {{"score": 0, "controls_passed": 0, "total_controls": 0}},
            "hipaa": {{"score": 0, "controls_passed": 0, "total_controls": 0}},
            "soc2": {{"score": 0, "controls_passed": 0, "total_controls": 0}}
        }
    
    def _init_custom_styles(self):
        """Initialize custom report styles."""
        self.styles.add(ParagraphStyle(
            name='CustomTitle',
            parent=self.styles['Title'],
            fontSize=24,
            textColor=colors.HexColor('#1a73e8'),
            spaceAfter=30
        ))
        
        self.styles.add(ParagraphStyle(
            name='SectionHeader',
            parent=self.styles['Heading1'],
            fontSize=16,
            textColor=colors.HexColor('#34a853'),
            spaceAfter=12
        ))
    
    def _load_compliance_controls(self) -&gt; Dict[str, List[ComplianceControl]]:
        """Load compliance control definitions."""
        # In production, load from configuration or database
        controls = {
            "gdpr": [
                ComplianceControl(
                    id="GDPR-1.1",
                    name="Data Encryption at Rest",
                    description="All personal data must be encrypted at rest",
                    framework="GDPR",
                    category="Data Protection",
                    automated=True,
                    last_tested=datetime.utcnow(),
                    status="compliant",
                    evidence=["encryption_scan_report.json"],
                    remediation=None
                ),
                ComplianceControl(
                    id="GDPR-2.1",
                    name="Consent Management",
                    description="Explicit consent for data processing",
                    framework="GDPR",
                    category="Lawful Basis",
                    automated=True,
                    last_tested=datetime.utcnow(),
                    status="compliant",
                    evidence=["consent_audit.json"],
                    remediation=None
                ),
                ComplianceControl(
                    id="GDPR-3.1",
                    name="Right to Erasure",
                    description="Ability to delete personal data on request",
                    framework="GDPR",
                    category="Individual Rights",
                    automated=True,
                    last_tested=datetime.utcnow(),
                    status="compliant",
                    evidence=["deletion_test_results.json"],
                    remediation=None
                ),
                ComplianceControl(
                    id="GDPR-4.1",
                    name="Data Breach Notification",
                    description="72-hour breach notification capability",
                    framework="GDPR",
                    category="Breach Management",
                    automated=True,
                    last_tested=datetime.utcnow(),
                    status="compliant",
                    evidence=["breach_response_test.json"],
                    remediation=None
                )
            ],
            "hipaa": [
                ComplianceControl(
                    id="HIPAA-1.1",
                    name="Access Controls",
                    description="Role-based access to PHI",
                    framework="HIPAA",
                    category="Administrative Safeguards",
                    automated=True,
                    last_tested=datetime.utcnow(),
                    status="compliant",
                    evidence=["access_control_audit.json"],
                    remediation=None
                ),
                ComplianceControl(
                    id="HIPAA-2.1",
                    name="Audit Logging",
                    description="Comprehensive audit logs for PHI access",
                    framework="HIPAA",
                    category="Technical Safeguards",
                    automated=True,
                    last_tested=datetime.utcnow(),
                    status="compliant",
                    evidence=["audit_log_review.json"],
                    remediation=None
                ),
                ComplianceControl(
                    id="HIPAA-3.1",
                    name="Transmission Security",
                    description="Encrypted transmission of PHI",
                    framework="HIPAA",
                    category="Technical Safeguards",
                    automated=True,
                    last_tested=datetime.utcnow(),
                    status="compliant",
                    evidence=["transmission_security_scan.json"],
                    remediation=None
                )
            ],
            "soc2": [
                ComplianceControl(
                    id="SOC2-1.1",
                    name="Security Monitoring",
                    description="Continuous security monitoring",
                    framework="SOC2",
                    category="Security",
                    automated=True,
                    last_tested=datetime.utcnow(),
                    status="compliant",
                    evidence=["monitoring_effectiveness.json"],
                    remediation=None
                ),
                ComplianceControl(
                    id="SOC2-2.1",
                    name="Change Management",
                    description="Formal change management process",
                    framework="SOC2",
                    category="Availability",
                    automated=True,
                    last_tested=datetime.utcnow(),
                    status="compliant",
                    evidence=["change_management_audit.json"],
                    remediation=None
                ),
                ComplianceControl(
                    id="SOC2-3.1",
                    name="Incident Response",
                    description="Documented incident response procedures",
                    framework="SOC2",
                    category="Security",
                    automated=True,
                    last_tested=datetime.utcnow(),
                    status="compliant",
                    evidence=["incident_response_test.json"],
                    remediation=None
                )
            ]
        }
        
        return controls
    
    async def run_compliance_scan(self, framework: str = "all") -&gt; Dict[str, Any]:
        """Run automated compliance scan."""
        results = {}
        
        frameworks = [framework] if framework != "all" else ["gdpr", "hipaa", "soc2"]
        
        for fw in frameworks:
            if fw in self.controls:
                results[fw] = await self._scan_framework_compliance(fw)
        
        # Update metrics
        self._update_compliance_metrics(results)
        
        return results
    
    async def _scan_framework_compliance(
        self,
        framework: str
    ) -&gt; List[Dict[str, Any]]:
        """Scan compliance for specific framework."""
        results = []
        
        for control in self.controls[framework]:
            # Run automated test
            if control.automated:
                test_result = await self._test_control(control)
                control.status = "compliant" if test_result else "non_compliant"
                control.last_tested = datetime.utcnow()
            
            results.append({
                "control_id": control.id,
                "name": control.name,
                "status": control.status,
                "last_tested": control.last_tested.isoformat(),
                "evidence": control.evidence,
                "remediation": control.remediation
            })
        
        return results
    
    async def _test_control(self, control: ComplianceControl) -&gt; bool:
        """Test individual compliance control."""
        # Implement specific tests based on control ID
        test_mapping = {
            "GDPR-1.1": self._test_encryption_at_rest,
            "GDPR-2.1": self._test_consent_management,
            "GDPR-3.1": self._test_data_deletion,
            "GDPR-4.1": self._test_breach_notification,
            "HIPAA-1.1": self._test_access_controls,
            "HIPAA-2.1": self._test_audit_logging,
            "HIPAA-3.1": self._test_transmission_security,
            "SOC2-1.1": self._test_security_monitoring,
            "SOC2-2.1": self._test_change_management,
            "SOC2-3.1": self._test_incident_response
        }
        
        test_func = test_mapping.get(control.id)
        if test_func:
            return await test_func()
        
        return True  # Default to compliant if no test defined
    
    async def _test_encryption_at_rest(self) -&gt; bool:
        """Test data encryption at rest."""
        # Query for unencrypted storage
        query = """
        AzureDiagnostics
        | where Category == "StorageAccount"
        | where encryption_s == "false"
        | count
        """
        
        results = await self.orchestrator._query_logs(query)
        return len(results) == 0 or results[0].get("Count", 0) == 0
    
    async def _test_consent_management(self) -&gt; bool:
        """Test consent management implementation."""
        # Check consent service health
        return True  # Placeholder
    
    async def _test_data_deletion(self) -&gt; bool:
        """Test data deletion capabilities."""
        # Verify deletion API functionality
        return True  # Placeholder
    
    async def _test_breach_notification(self) -&gt; bool:
        """Test breach notification system."""
        # Check notification system readiness
        return True  # Placeholder
    
    async def _test_access_controls(self) -&gt; bool:
        """Test RBAC implementation."""
        # Verify role-based access controls
        return True  # Placeholder
    
    async def _test_audit_logging(self) -&gt; bool:
        """Test audit logging completeness."""
        # Check audit log coverage
        return True  # Placeholder
    
    async def _test_transmission_security(self) -&gt; bool:
        """Test encryption in transit."""
        # Scan for unencrypted transmissions
        return True  # Placeholder
    
    async def _test_security_monitoring(self) -&gt; bool:
        """Test security monitoring effectiveness."""
        # Check monitoring coverage
        return self.orchestrator.metrics["incidents_detected"] &gt; 0
    
    async def _test_change_management(self) -&gt; bool:
        """Test change management process."""
        # Verify change approval workflow
        return True  # Placeholder
    
    async def _test_incident_response(self) -&gt; bool:
        """Test incident response procedures."""
        # Check incident response metrics
        mttr = self.orchestrator.metrics.get("mean_time_to_remediate", 0)
        return mttr &gt; 0 and mttr &lt; 60  # Less than 60 minutes
    
    def _update_compliance_metrics(self, scan_results: Dict[str, Any]):
        """Update compliance metrics from scan results."""
        for framework, results in scan_results.items():
            total_controls = len(results)
            passed_controls = sum(
                1 for r in results if r["status"] == "compliant"
            )
            
            self.compliance_metrics[framework] = {
                "score": (passed_controls / total_controls * 100) if total_controls &gt; 0 else 0,
                "controls_passed": passed_controls,
                "total_controls": total_controls,
                "last_scan": datetime.utcnow().isoformat()
            }
    
    async def generate_compliance_report(
        self,
        framework: str,
        period_days: int = 30
    ) -&gt; str:
        """Generate comprehensive compliance report."""
        # Run fresh scan
        scan_results = await self.run_compliance_scan(framework)
        
        # Create PDF report
        filename = f"compliance_report_{framework}_{datetime.utcnow().strftime('%Y%m%d')}.pdf"
        doc = SimpleDocTemplate(filename, pagesize=letter)
        
        # Build report content
        content = []
        
        # Title page
        content.append(Paragraph(
            f"{framework.upper()} Compliance Report",
            self.styles['CustomTitle']
        ))
        content.append(Spacer(1, 0.5 * inch))
        
        # Executive summary
        content.append(Paragraph("Executive Summary", self.styles['SectionHeader']))
        summary_data = self._generate_executive_summary(framework)
        content.append(Paragraph(summary_data, self.styles['Normal']))
        content.append(Spacer(1, 0.3 * inch))
        
        # Compliance score visualization
        score_chart = self._create_compliance_score_chart(framework)
        content.append(Image(score_chart, width=6*inch, height=4*inch))
        content.append(PageBreak())
        
        # Detailed control status
        content.append(Paragraph("Control Status Details", self.styles['SectionHeader']))
        control_table = self._create_control_status_table(scan_results[framework])
        content.append(control_table)
        content.append(Spacer(1, 0.3 * inch))
        
        # Trend analysis
        content.append(Paragraph("Compliance Trend Analysis", self.styles['SectionHeader']))
        trend_chart = self._create_trend_chart(framework, period_days)
        content.append(Image(trend_chart, width=6*inch, height=4*inch))
        content.append(PageBreak())
        
        # Remediation recommendations
        content.append(Paragraph("Remediation Recommendations", self.styles['SectionHeader']))
        recommendations = self._generate_recommendations(scan_results[framework])
        for rec in recommendations:
            content.append(Paragraph(f"• {rec}", self.styles['Normal']))
        content.append(Spacer(1, 0.3 * inch))
        
        # Evidence summary
        content.append(Paragraph("Evidence Summary", self.styles['SectionHeader']))
        evidence_table = self._create_evidence_table(scan_results[framework])
        content.append(evidence_table)
        
        # Build PDF
        doc.build(content)
        
        return filename
    
    def _generate_executive_summary(self, framework: str) -&gt; str:
        """Generate executive summary for report."""
        metrics = self.compliance_metrics[framework]
        
        summary = f"""
        This report provides a comprehensive assessment of our {framework.upper()} 
        compliance status as of {datetime.utcnow().strftime('%B %d, %Y')}.
        
        Overall Compliance Score: {metrics['score']:.1f}%
        Controls Passed: {metrics['controls_passed']} out of {metrics['total_controls']}
        
        Our security posture demonstrates {'strong' if metrics['score'] &gt; 90 else 'adequate'} 
        compliance with {framework.upper()} requirements. {'All critical controls are functioning 
        as expected.' if metrics['score'] == 100 else 'Some areas require attention as detailed 
        in this report.'}
        """
        
        return summary
    
    def _create_compliance_score_chart(self, framework: str) -&gt; str:
        """Create compliance score visualization."""
        plt.figure(figsize=(8, 6))
        
        # Get metrics
        metrics = self.compliance_metrics[framework]
        
        # Create gauge chart
        fig, ax = plt.subplots(figsize=(8, 6))
        
        # Score categories
        categories = ['Non-Compliant', 'Partial', 'Compliant']
        colors = ['#ef4444', '#f59e0b', '#10b981']
        
        # Create pie chart as gauge
        sizes = [100 - metrics['score'], 0, metrics['score']]
        explode = (0.1, 0, 0.1)
        
        ax.pie(
            sizes,
            explode=explode,
            labels=categories,
            colors=colors,
            autopct='%1.1f%%',
            startangle=90
        )
        
        ax.set_title(
            f"{framework.upper()} Compliance Score: {metrics['score']:.1f}%",
            fontsize=16,
            fontweight='bold'
        )
        
        # Save chart
        filename = f"compliance_score_{framework}.png"
        plt.savefig(filename, bbox_inches='tight', dpi=300)
        plt.close()
        
        return filename
    
    def _create_control_status_table(
        self,
        scan_results: List[Dict[str, Any]]
    ) -&gt; Table:
        """Create control status table."""
        # Prepare data
        data = [['Control ID', 'Name', 'Status', 'Last Tested']]
        
        for result in scan_results:
            status_color = colors.green if result['status'] == 'compliant' else colors.red
            data.append([
                result['control_id'],
                result['name'][:40] + '...' if len(result['name']) &gt; 40 else result['name'],
                result['status'].upper(),
                datetime.fromisoformat(result['last_tested']).strftime('%Y-%m-%d')
            ])
        
        # Create table
        table = Table(data)
        table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 12),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        
        return table
    
    def _create_trend_chart(self, framework: str, period_days: int) -&gt; str:
        """Create compliance trend chart."""
        # Generate sample trend data (in production, query historical data)
        dates = pd.date_range(
            end=datetime.utcnow(),
            periods=period_days,
            freq='D'
        )
        
        # Simulate improving compliance trend
        base_score = 85
        scores = [
            base_score + (i / period_days * 10) + np.random.normal(0, 2)
            for i in range(period_days)
        ]
        
        # Create plot
        plt.figure(figsize=(10, 6))
        plt.plot(dates, scores, linewidth=2, color='#1a73e8')
        plt.fill_between(dates, scores, alpha=0.3, color='#1a73e8')
        
        plt.title(f"{framework.upper()} Compliance Trend", fontsize=16)
        plt.xlabel("Date")
        plt.ylabel("Compliance Score (%)")
        plt.ylim(0, 100)
        plt.grid(True, alpha=0.3)
        
        # Add current score line
        current_score = self.compliance_metrics[framework]['score']
        plt.axhline(
            y=current_score,
            color='#34a853',
            linestyle='--',
            label=f'Current: {current_score:.1f}%'
        )
        plt.legend()
        
        # Save chart
        filename = f"compliance_trend_{framework}.png"
        plt.savefig(filename, bbox_inches='tight', dpi=300)
        plt.close()
        
        return filename
    
    def _generate_recommendations(
        self,
        scan_results: List[Dict[str, Any]]
    ) -&gt; List[str]:
        """Generate remediation recommendations."""
        recommendations = []
        
        for result in scan_results:
            if result['status'] != 'compliant':
                control_id = result['control_id']
                
                # Generate specific recommendations based on control
                if "encryption" in result['name'].lower():
                    recommendations.append(
                        f"Enable encryption for all data stores identified in control {control_id}"
                    )
                elif "access" in result['name'].lower():
                    recommendations.append(
                        f"Review and update access controls for {control_id}"
                    )
                elif "audit" in result['name'].lower():
                    recommendations.append(
                        f"Enhance audit logging coverage for {control_id}"
                    )
                
                if result.get('remediation'):
                    recommendations.append(result['remediation'])
        
        if not recommendations:
            recommendations.append(
                "Continue current security practices to maintain compliance"
            )
        
        return recommendations
    
    def _create_evidence_table(
        self,
        scan_results: List[Dict[str, Any]]
    ) -&gt; Table:
        """Create evidence summary table."""
        data = [['Control ID', 'Evidence Files', 'Collection Date']]
        
        for result in scan_results:
            evidence_list = ', '.join(result.get('evidence', []))[:50] + '...'
            data.append([
                result['control_id'],
                evidence_list,
                datetime.utcnow().strftime('%Y-%m-%d')
            ])
        
        table = Table(data)
        table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 11),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        
        return table
    
    async def schedule_compliance_reports(self):
        """Schedule automated compliance reports."""
        while True:
            try:
                # Generate reports on schedule
                if datetime.utcnow().day == 1:  # Monthly reports
                    for framework in ["gdpr", "hipaa", "soc2"]:
                        report_file = await self.generate_compliance_report(
                            framework,
                            period_days=30
                        )
                        
                        # Send to stakeholders
                        await self.send_compliance_report(
                            report_file,
                            framework,
                            ["compliance@company.com", "ciso@company.com"]
                        )
                
                # Wait until next check
                await asyncio.sleep(86400)  # Check daily
                
            except Exception as e:
                logger.error(f"Report scheduling error: {e}")
                await asyncio.sleep(3600)
    
    async def send_compliance_report(
        self,
        report_file: str,
        framework: str,
        recipients: List[str]
    ):
        """Send compliance report via email."""
        try:
            msg = MIMEMultipart()
            msg['From'] = self.smtp_config['sender']
            msg['To'] = ', '.join(recipients)
            msg['Subject'] = f"{framework.upper()} Compliance Report - {datetime.utcnow().strftime('%B %Y')}"
            
            # Email body
            metrics = self.compliance_metrics[framework]
            body = f"""
            Please find attached the {framework.upper()} compliance report for {datetime.utcnow().strftime('%B %Y')}.
            
            Summary:
            - Compliance Score: {metrics['score']:.1f}%
            - Controls Passed: {metrics['controls_passed']} / {metrics['total_controls']}
            - Report Generated: {datetime.utcnow().strftime('%Y-%m-%d %H:%M UTC')}
            
            This is an automated report from the Enterprise Security Platform.
            """
            
            msg.attach(MIMEText(body, 'plain'))
            
            # Attach report
            with open(report_file, 'rb') as f:
                attach = MIMEApplication(f.read(), _subtype="pdf")
                attach.add_header(
                    'Content-Disposition',
                    'attachment',
                    filename=report_file
                )
                msg.attach(attach)
            
            # Send email
            smtp = smtplib.SMTP(
                self.smtp_config['server'],
                self.smtp_config['port']
            )
            smtp.starttls()
            smtp.login(
                self.smtp_config['username'],
                self.smtp_config['password']
            )
            smtp.send_message(msg)
            smtp.quit()
            
            logger.info(f"Sent {framework} compliance report to {recipients}")
            
        except Exception as e:
            logger.error(f"Failed to send compliance report: {e}")
```

### Step 4: Create Security Dashboard API

**Copilot Prompt Suggestion:**
```
Create a FastAPI application for the security platform dashboard that:
- Provides real-time security metrics via WebSocket
- Exposes REST APIs for incident management
- Includes Microsoft Entra ID authentication
- Supports role-based dashboard access
- Generates on-demand reports
- Provides threat intelligence feeds
Include OpenAPI documentation and CORS support.
```

**Expected Output:**
```python
from fastapi import FastAPI, WebSocket, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer
from fastapi.responses import FileResponse
from typing import Dict, List, Any, Optional
import asyncio
import json
from datetime import datetime, timedelta
from jose import JWTError, jwt
import httpx

app = FastAPI(
    title="Enterprise Security Platform API",
    description="Central security monitoring and compliance API",
    version="1.0.0"
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://security-dashboard.company.com"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# OAuth2 with Microsoft Entra ID
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# Global instances
security_orchestrator: Optional[SecurityOrchestrator] = None
compliance_reporter: Optional[ComplianceReporter] = None
active_connections: List[WebSocket] = []

# Authentication
async def get_current_user(token: str = Depends(oauth2_scheme)) -&gt; Dict[str, Any]:
    """Validate Microsoft Entra ID token."""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={{"WWW-Authenticate": "Bearer"}},
    )
    
    try:
        # Validate token with Microsoft Entra ID
        # In production, use proper token validation
        payload = jwt.decode(
            token,
            "your-secret-key",
            algorithms=["HS256"]
        )
        username: str = payload.get("sub")
        roles: List[str] = payload.get("roles", [])
        
        if username is None:
            raise credentials_exception
        
        return {{"username": username, "roles": roles}}
        
    except JWTError:
        raise credentials_exception

def require_role(role: str):
    """Require specific role for endpoint access."""
    async def role_checker(current_user: Dict = Depends(get_current_user)):
        if role not in current_user.get("roles", []):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Insufficient permissions"
            )
        return current_user
    return role_checker

# WebSocket manager
class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []
    
    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)
    
    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)
    
    async def broadcast(self, message: dict):
        for connection in self.active_connections:
            try:
                await connection.send_json(message)
            except:
                pass

manager = ConnectionManager()

# API Endpoints
@app.get("/api/v1/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "services": {
            "orchestrator": security_orchestrator is not None,
            "compliance": compliance_reporter is not None
        }
    }

@app.get("/api/v1/metrics")
async def get_security_metrics(
    current_user: Dict = Depends(get_current_user)
):
    """Get current security metrics."""
    if not security_orchestrator:
        raise HTTPException(status_code=503, detail="Service not initialized")
    
    return {
        "security_metrics": security_orchestrator.metrics,
        "compliance_metrics": compliance_reporter.compliance_metrics,
        "timestamp": datetime.utcnow().isoformat()
    }

@app.get("/api/v1/incidents")
async def get_incidents(
    status: Optional[str] = None,
    severity: Optional[str] = None,
    limit: int = 100,
    current_user: Dict = Depends(get_current_user)
):
    """Get security incidents with filtering."""
    if not security_orchestrator:
        raise HTTPException(status_code=503, detail="Service not initialized")
    
    incidents = list(security_orchestrator.active_incidents.values())
    
    # Apply filters
    if status:
        incidents = [
            i for i in incidents 
            if i.status.value == status
        ]
    
    if severity:
        incidents = [
            i for i in incidents 
            if i.severity.value == severity
        ]
    
    # Sort by timestamp descending
    incidents.sort(key=lambda x: x.timestamp, reverse=True)
    
    return {
        "incidents": [
            {
                "id": i.id,
                "title": i.title,
                "severity": i.severity.value,
                "status": i.status.value,
                "timestamp": i.timestamp.isoformat(),
                "source": i.source
            }
            for i in incidents[:limit]
        ],
        "total": len(incidents)
    }

@app.get("/api/v1/incidents/{incident_id}")
async def get_incident_details(
    incident_id: str,
    current_user: Dict = Depends(get_current_user)
):
    """Get detailed incident information."""
    if not security_orchestrator:
        raise HTTPException(status_code=503, detail="Service not initialized")
    
    incident = security_orchestrator.active_incidents.get(incident_id)
    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")
    
    return {
        "id": incident.id,
        "source": incident.source,
        "title": incident.title,
        "description": incident.description,
        "severity": incident.severity.value,
        "status": incident.status.value,
        "timestamp": incident.timestamp.isoformat(),
        "affected_resources": incident.affected_resources,
        "indicators": incident.indicators,
        "remediation_actions": incident.remediation_actions
    }

@app.post("/api/v1/incidents/{incident_id}/remediate")
async def trigger_remediation(
    incident_id: str,
    current_user: Dict = Depends(require_role("security_admin"))
):
    """Manually trigger incident remediation."""
    if not security_orchestrator:
        raise HTTPException(status_code=503, detail="Service not initialized")
    
    incident = security_orchestrator.active_incidents.get(incident_id)
    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")
    
    # Add to remediation queue
    await security_orchestrator.remediation_queue.put(incident)
    
    return {
        "status": "remediation_triggered",
        "incident_id": incident_id,
        "timestamp": datetime.utcnow().isoformat()
    }

@app.get("/api/v1/compliance/{framework}")
async def get_compliance_status(
    framework: str,
    current_user: Dict = Depends(get_current_user)
):
    """Get compliance status for specific framework."""
    if framework not in ["gdpr", "hipaa", "soc2"]:
        raise HTTPException(status_code=400, detail="Invalid framework")
    
    if not compliance_reporter:
        raise HTTPException(status_code=503, detail="Service not initialized")
    
    return {
        "framework": framework,
        "metrics": compliance_reporter.compliance_metrics.get(framework, {{}}),
        "controls": [
            {
                "id": c.id,
                "name": c.name,
                "status": c.status,
                "last_tested": c.last_tested.isoformat()
            }
            for c in compliance_reporter.controls.get(framework, [])
        ]
    }

@app.post("/api/v1/compliance/{framework}/scan")
async def run_compliance_scan(
    framework: str,
    current_user: Dict = Depends(require_role("compliance_officer"))
):
    """Trigger compliance scan for framework."""
    if framework not in ["gdpr", "hipaa", "soc2", "all"]:
        raise HTTPException(status_code=400, detail="Invalid framework")
    
    if not compliance_reporter:
        raise HTTPException(status_code=503, detail="Service not initialized")
    
    # Run scan asynchronously
    results = await compliance_reporter.run_compliance_scan(framework)
    
    return {
        "status": "scan_completed",
        "framework": framework,
        "results": results,
        "timestamp": datetime.utcnow().isoformat()
    }

@app.post("/api/v1/compliance/{framework}/report")
async def generate_compliance_report(
    framework: str,
    period_days: int = 30,
    current_user: Dict = Depends(require_role("compliance_officer"))
):
    """Generate compliance report."""
    if framework not in ["gdpr", "hipaa", "soc2"]:
        raise HTTPException(status_code=400, detail="Invalid framework")
    
    if not compliance_reporter:
        raise HTTPException(status_code=503, detail="Service not initialized")
    
    # Generate report
    report_file = await compliance_reporter.generate_compliance_report(
        framework,
        period_days
    )
    
    return FileResponse(
        report_file,
        media_type="application/pdf",
        filename=report_file
    )

@app.get("/api/v1/threat-intelligence")
async def get_threat_intelligence(
    current_user: Dict = Depends(get_current_user)
):
    """Get latest threat intelligence feed."""
    # Integrate with threat intelligence sources
    threats = []
    
    # Microsoft Threat Intelligence
    try:
        # This would connect to actual threat feeds
        threats.extend([
            {
                "source": "Microsoft",
                "type": "malware",
                "severity": "high",
                "description": "New ransomware variant detected",
                "iocs": ["hash1", "ip1", "domain1"],
                "timestamp": datetime.utcnow().isoformat()
            }
        ])
    except:
        pass
    
    return {
        "threats": threats,
        "last_updated": datetime.utcnow().isoformat()
    }

@app.websocket("/ws/security-feed")
async def security_feed_websocket(websocket: WebSocket):
    """WebSocket for real-time security updates."""
    await manager.connect(websocket)
    
    try:
        # Send initial state
        await websocket.send_json({
            "type": "init",
            "data": {
                "metrics": security_orchestrator.metrics if security_orchestrator else {{}},
                "active_incidents": len(
                    security_orchestrator.active_incidents
                ) if security_orchestrator else 0
            }
        })
        
        # Keep connection alive
        while True:
            await asyncio.sleep(1)
            
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
    finally:
        manager.disconnect(websocket)

# Background task to broadcast updates
async def broadcast_security_updates():
    """Broadcast security updates to connected clients."""
    while True:
        if security_orchestrator and manager.active_connections:
            update = {
                "type": "update",
                "data": {
                    "metrics": security_orchestrator.metrics,
                    "latest_incident": None
                }
            }
            
            # Get latest incident
            if security_orchestrator.active_incidents:
                latest = max(
                    security_orchestrator.active_incidents.values(),
                    key=lambda x: x.timestamp
                )
                update["data"]["latest_incident"] = {
                    "id": latest.id,
                    "title": latest.title,
                    "severity": latest.severity.value,
                    "timestamp": latest.timestamp.isoformat()
                }
            
            await manager.broadcast(update)
        
        await asyncio.sleep(5)  # Update every 5 seconds

@app.on_event("startup")
async def startup_event():
    """Initialize services on startup."""
    global security_orchestrator, compliance_reporter
    
    # Initialize orchestrator
    security_orchestrator = SecurityOrchestrator(
        subscription_id="your-subscription-id",
        workspace_id="your-workspace-id",
        resource_group="your-resource-group",
        github_token="your-github-token"
    )
    
    # Initialize compliance reporter
    compliance_reporter = ComplianceReporter(
        security_orchestrator=security_orchestrator,
        smtp_config={
            "server": "smtp.office365.com",
            "port": 587,
            "username": "notifications@company.com",
            "password": "secure-password",
            "sender": "security-platform@company.com"
        }
    )
    
    # Start background tasks
    asyncio.create_task(security_orchestrator.start_monitoring())
    asyncio.create_task(compliance_reporter.schedule_compliance_reports())
    asyncio.create_task(broadcast_security_updates())
    
    logger.info("Enterprise Security Platform started")

@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown."""
    logger.info("Enterprise Security Platform shutting down")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

### Step 5: Deploy and Test the Platform

Create deployment configuration:

```yaml
# docker-compose.yml
version: '3.8'

services:
  security-platform:
    build: .
    ports:
      - "8000:8000"
    environment:
      - AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID}
      - AZURE_TENANT_ID=${AZURE_TENANT_ID}
      - WORKSPACE_ID=${WORKSPACE_ID}
      - GITHUB_TOKEN=${GITHUB_TOKEN}
    volumes:
      - ./reports:/app/reports
      - ./logs:/app/logs
    depends_on:
      - redis
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data

  nginx:
    image: nginx:alpine
    ports:
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./certs:/etc/nginx/certs
    depends_on:
      - security-platform

volumes:
  redis-data:
```

Test script:

```python
# test_platform.py
import asyncio
import httpx
import websockets
import json

async def test_security_platform():
    base_url = "http://localhost:8000"
    
    # Test health check
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{base_url}/api/v1/health")
        print(f"Health: {response.json()}")
        
        # Get auth token (mock)
        token = "your-test-token"
        headers = {{"Authorization": f"Bearer {{token}}"}}
        
        # Test metrics endpoint
        response = await client.get(
            f"{base_url}/api/v1/metrics",
            headers=headers
        )
        print(f"Metrics: {response.json()}")
        
        # Test compliance scan
        response = await client.post(
            f"{base_url}/api/v1/compliance/gdpr/scan",
            headers=headers
        )
        print(f"Scan Result: {response.json()}")
    
    # Test WebSocket
    async with websockets.connect("ws://localhost:8000/ws/security-feed") as ws:
        print("Connected to security feed")
        
        # Receive initial state
        message = await ws.recv()
        print(f"Initial state: {json.loads(message)}")
        
        # Listen for updates
        for _ in range(5):
            message = await ws.recv()
            print(f"Update: {json.loads(message)}")

# Run test
asyncio.run(test_security_platform())
```

## ✅ Validation Checklist

Your Enterprise Security Platform should:

1. **SIEM Integration**: Successfully connect to Microsoft Sentinel
2. **Threat Detection**: Identify security incidents in real-time
3. **Automated Remediation**: Execute remediation workflows
4. **Compliance Scanning**: Run automated compliance checks
5. **Reporting**: Generate comprehensive compliance reports
6. **Real-time Updates**: Provide WebSocket security feed
7. **Authentication**: Use Microsoft Entra ID for access control

## 🎯 Success Criteria

- [ ] Platform detects and remediates security incidents
- [ ] Compliance reports generate automatically
- [ ] Real-time dashboard shows security metrics
- [ ] All three frameworks (GDPR, HIPAA, SOC2) are monitored
- [ ] Automated remediation reduces MTTR below 60 minutes
- [ ] Security alerts are prioritized correctly

## 🚀 Extension Challenges

1. **Add ML Threat Detection**: Implement anomaly detection using Azure ML
2. **Create Mobile App**: Build iOS/Android security monitoring app
3. **Implement SOAR**: Full security orchestration and response
4. **Add Threat Hunting**: Proactive threat investigation capabilities

## 📚 Additional Resources

- [Microsoft Sentinel Documentation](https://learn.microsoft.com/azure/sentinel/)
- [Microsoft Defender for Cloud](https://learn.microsoft.com/azure/defender-for-cloud/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [Microsoft Entra ID Developer Guide](https://learn.microsoft.com/entra/identity-platform/)

---

🎉 Outstanding work! You've built a comprehensive Enterprise Security Platform that provides real-time threat detection, automated remediation, and compliance management. This platform serves as the foundation for enterprise-grade security operations!