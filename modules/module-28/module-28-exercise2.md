# Exercise 2: AI Security Operations (⭐⭐ Medium - 45 minutes)

## 🎯 Objective
Build an autonomous AI-powered Security Operations Center (SOC) that detects threats, responds to incidents, ensures compliance, and learns from security events without human intervention.

## 🧠 What You'll Learn
- Creating AI security agents
- Automated threat detection
- Intelligent incident response
- Security orchestration
- Compliance automation
- Real-time security analytics
- Multi-agent security coordination

## 📋 Prerequisites
- Completed Exercise 1
- Security fundamentals
- Python async programming
- Understanding of SIEM concepts
- Basic knowledge of security frameworks

## 📚 Background

Traditional SOCs are overwhelmed with alerts, false positives, and manual processes. An AI-powered SOC:

- **Detects**: Identifies threats using ML and behavioral analysis
- **Investigates**: Automatically gathers context and evidence
- **Responds**: Takes immediate action to contain threats
- **Learns**: Improves detection based on outcomes
- **Complies**: Ensures continuous compliance with regulations

## 🏗️ Architecture

```mermaid
graph TB
    subgraph "Data Sources"
        LOGS[Application Logs]
        NETWORK[Network Traffic]
        ENDPOINTS[Endpoint Data]
        CLOUD[Cloud Events]
        THREAT_INTEL[Threat Intelligence]
    end
    
    subgraph "AI Security Agents"
        DETECTOR[Threat Detection Agent]
        INVESTIGATOR[Investigation Agent]
        RESPONDER[Response Agent]
        COMPLIANCE[Compliance Agent]
        HUNTER[Threat Hunting Agent]
        FORENSICS[Forensics Agent]
    end
    
    subgraph "AI Core"
        ML_ENGINE[ML Engine]
        NLP[NLP Processor]
        BEHAVIOR[Behavioral Analysis]
        ANOMALY[Anomaly Detection]
        PREDICTOR[Threat Predictor]
    end
    
    subgraph "Security Tools"
        SIEM[SIEM Platform]
        SOAR[SOAR Platform]
        EDR[EDR Solution]
        WAF[Web Application Firewall]
        SCANNER[Vulnerability Scanner]
    end
    
    subgraph "Response Actions"
        BLOCK[Block IP/User]
        ISOLATE[Isolate System]
        PATCH[Auto-Patch]
        ALERT[Alert Team]
        REPORT[Generate Report]
    end
    
    LOGS --> DETECTOR
    NETWORK --> DETECTOR
    ENDPOINTS --> DETECTOR
    CLOUD --> DETECTOR
    THREAT_INTEL --> DETECTOR
    
    DETECTOR --> ML_ENGINE
    ML_ENGINE --> INVESTIGATOR
    
    INVESTIGATOR --> NLP
    INVESTIGATOR --> BEHAVIOR
    INVESTIGATOR --> ANOMALY
    
    INVESTIGATOR --> RESPONDER
    RESPONDER --> PREDICTOR
    
    RESPONDER --> BLOCK
    RESPONDER --> ISOLATE
    RESPONDER --> PATCH
    RESPONDER --> ALERT
    
    DETECTOR --> SIEM
    INVESTIGATOR --> SOAR
    RESPONDER --> EDR
    RESPONDER --> WAF
    
    COMPLIANCE --> SCANNER
    COMPLIANCE --> REPORT
    
    HUNTER --> FORENSICS
    FORENSICS --> REPORT
    
    style DETECTOR fill:#EF4444
    style ML_ENGINE fill:#3B82F6
    style RESPONDER fill:#10B981
    style COMPLIANCE fill:#F59E0B
```

## 🛠️ Step-by-Step Instructions

### Step 1: Create Security Intelligence Engine

**Copilot Prompt Suggestion:**
```python
# Create an AI-powered security intelligence engine that:
# - Processes multiple data sources (logs, network, endpoints)
# - Uses ML for threat detection
# - Performs behavioral analysis
# - Generates threat intelligence
# - Includes real-time processing
# Use async patterns and streaming for performance
```

Create `agents/security_agent.py`:
```python
import asyncio
import json
import re
from typing import Dict, List, Any, Optional, AsyncIterator
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
import numpy as np
from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import StandardScaler
import tensorflow as tf
import openai
import structlog
import aiohttp
import asyncpg
from elasticsearch import AsyncElasticsearch
from prometheus_client import Counter, Histogram, Gauge
import yara
import hashlib
from collections import defaultdict
import networkx as nx

logger = structlog.get_logger()

class ThreatSeverity(Enum):
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"
    INFO = "info"

@dataclass
class SecurityEvent:
    """Security event data structure"""
    id: str
    timestamp: datetime
    source: str
    event_type: str
    severity: ThreatSeverity
    data: Dict[str, Any]
    raw_log: Optional[str] = None
    indicators: List[str] = field(default_factory=list)
    context: Dict[str, Any] = field(default_factory=dict)

@dataclass
class ThreatIndicator:
    """Indicator of Compromise (IoC)"""
    type: str  # ip, domain, hash, email, url
    value: str
    threat_type: str
    confidence: float
    source: str
    last_seen: datetime
    metadata: Dict[str, Any] = field(default_factory=dict)

@dataclass
class SecurityIncident:
    """Security incident requiring response"""
    id: str
    severity: ThreatSeverity
    title: str
    description: str
    affected_assets: List[str]
    indicators: List[ThreatIndicator]
    timeline: List[SecurityEvent]
    response_actions: List[Dict[str, Any]] = field(default_factory=list)
    status: str = "open"
    created_at: datetime = field(default_factory=datetime.now)

class SecurityIntelligenceEngine:
    """AI-powered security intelligence and threat detection"""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.ml_models = {}
        self.threat_intel_sources = []
        self.yara_rules = []
        self.behavioral_baselines = {}
        self.scaler = StandardScaler()
        
        # Metrics
        self.events_processed = Counter('security_events_processed_total')
        self.threats_detected = Counter('threats_detected_total')
        self.incident_response_time = Histogram('incident_response_duration_seconds')
        self.active_incidents = Gauge('active_security_incidents')
        
        # Initialize connections
        self.es_client = AsyncElasticsearch([config['elasticsearch_url']])
        self.db_pool = None
        self.threat_graph = nx.DiGraph()
        
    async def initialize(self):
        """Initialize the security engine"""
        logger.info("Initializing Security Intelligence Engine")
        
        # Initialize database pool
        self.db_pool = await asyncpg.create_pool(
            self.config['database_url'],
            min_size=10,
            max_size=20
        )
        
        # Load ML models
        await self.load_ml_models()
        
        # Load YARA rules
        await self.load_yara_rules()
        
        # Initialize threat intelligence feeds
        await self.initialize_threat_intel()
        
        # Build behavioral baselines
        await self.build_behavioral_baselines()
        
        logger.info("Security Intelligence Engine initialized")
    
    async def load_ml_models(self):
        """Load pre-trained ML models for threat detection"""
        
        # Anomaly detection model
        self.ml_models['anomaly'] = IsolationForest(
            contamination=0.01,
            random_state=42,
            n_estimators=100
        )
        
        # Load deep learning model for advanced threat detection
        if self.config.get('deep_learning_model_path'):
            self.ml_models['deep_learning'] = tf.keras.models.load_model(
                self.config['deep_learning_model_path']
            )
        
        # Train anomaly model with historical data if available
        if await self.has_historical_data():
            await self.train_anomaly_model()
    
    async def load_yara_rules(self):
        """Load YARA rules for pattern matching"""
        rules_path = self.config.get('yara_rules_path', 'rules/')
        
        # Example YARA rules
        malware_rule = """
        rule suspicious_powershell {
            strings:
                $a = "powershell" nocase
                $b = "-enc" nocase
                $c = "bypass" nocase
                $d = "hidden" nocase
            condition:
                2 of them
        }
        
        rule crypto_ransomware {
            strings:
                $crypto1 = "AES" nocase
                $crypto2 = "RSA" nocase
                $ransom1 = "bitcoin" nocase
                $ransom2 = "decrypt" nocase
                $ransom3 = "pay" nocase
            condition:
                any of ($crypto*) and 2 of ($ransom*)
        }
        """
        
        self.yara_rules = yara.compile(source=malware_rule)
    
    async def process_event_stream(self, event_stream: AsyncIterator[Dict[str, Any]]):
        """Process incoming security events"""
        
        async for raw_event in event_stream:
            try:
                # Parse event
                event = await self.parse_event(raw_event)
                
                # Enrich with context
                event = await self.enrich_event(event)
                
                # Detect threats
                threats = await self.detect_threats(event)
                
                if threats:
                    # Create or update incident
                    incident = await self.correlate_to_incident(event, threats)
                    
                    # Trigger response
                    await self.trigger_response(incident)
                
                # Store event
                await self.store_event(event)
                
                # Update metrics
                self.events_processed.inc()
                
            except Exception as e:
                logger.error(f"Error processing event: {e}", event=raw_event)
    
    async def parse_event(self, raw_event: Dict[str, Any]) -> SecurityEvent:
        """Parse raw event into SecurityEvent"""
        
        # Extract common fields
        event = SecurityEvent(
            id=raw_event.get('id', self.generate_event_id()),
            timestamp=datetime.fromisoformat(raw_event.get('timestamp', datetime.now().isoformat())),
            source=raw_event.get('source', 'unknown'),
            event_type=raw_event.get('type', 'generic'),
            severity=ThreatSeverity.INFO,
            data=raw_event.get('data', {}),
            raw_log=raw_event.get('raw_log')
        )
        
        # Extract indicators
        event.indicators = await self.extract_indicators(raw_event)
        
        return event
    
    async def extract_indicators(self, event: Dict[str, Any]) -> List[str]:
        """Extract IoCs from event"""
        indicators = []
        
        # Patterns for different indicator types
        patterns = {
            'ip': r'\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b',
            'domain': r'\b(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\b',
            'email': r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
            'url': r'https?://(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)',
            'hash_md5': r'\b[a-fA-F0-9]{32}\b',
            'hash_sha256': r'\b[a-fA-F0-9]{64}\b'
        }
        
        # Search for patterns in event data
        event_str = json.dumps(event)
        
        for indicator_type, pattern in patterns.items():
            matches = re.findall(pattern, event_str, re.IGNORECASE)
            indicators.extend(matches)
        
        return list(set(indicators))  # Remove duplicates
    
    async def enrich_event(self, event: SecurityEvent) -> SecurityEvent:
        """Enrich event with additional context"""
        
        # GeoIP enrichment
        for indicator in event.indicators:
            if self.is_ip_address(indicator):
                geo_data = await self.get_geoip_data(indicator)
                event.context[f'geoip_{indicator}'] = geo_data
        
        # Threat intelligence enrichment
        threat_data = await self.check_threat_intel(event.indicators)
        if threat_data:
            event.context['threat_intel'] = threat_data
        
        # User context
        if user_id := event.data.get('user_id'):
            user_context = await self.get_user_context(user_id)
            event.context['user'] = user_context
        
        # Asset context
        if asset_id := event.data.get('asset_id'):
            asset_context = await self.get_asset_context(asset_id)
            event.context['asset'] = asset_context
        
        return event
    
    async def detect_threats(self, event: SecurityEvent) -> List[Dict[str, Any]]:
        """Detect threats using multiple detection methods"""
        threats = []
        
        # 1. Rule-based detection (YARA)
        if yara_matches := await self.yara_scan(event):
            threats.extend(yara_matches)
        
        # 2. Anomaly detection
        if anomalies := await self.detect_anomalies(event):
            threats.extend(anomalies)
        
        # 3. Behavioral analysis
        if behavioral_threats := await self.analyze_behavior(event):
            threats.extend(behavioral_threats)
        
        # 4. Machine learning detection
        if ml_threats := await self.ml_detection(event):
            threats.extend(ml_threats)
        
        # 5. Threat intelligence matching
        if intel_threats := await self.threat_intel_matching(event):
            threats.extend(intel_threats)
        
        # 6. AI-based analysis
        if ai_threats := await self.ai_threat_analysis(event):
            threats.extend(ai_threats)
        
        return threats
    
    async def yara_scan(self, event: SecurityEvent) -> List[Dict[str, Any]]:
        """Scan event with YARA rules"""
        threats = []
        
        # Scan raw log if available
        if event.raw_log:
            matches = self.yara_rules.match(data=event.raw_log)
            
            for match in matches:
                threats.append({
                    'type': 'yara_match',
                    'rule': match.rule,
                    'severity': ThreatSeverity.HIGH,
                    'confidence': 0.9,
                    'description': f"YARA rule '{match.rule}' matched"
                })
        
        return threats
    
    async def detect_anomalies(self, event: SecurityEvent) -> List[Dict[str, Any]]:
        """Detect anomalies using ML"""
        threats = []
        
        # Extract features
        features = await self.extract_features(event)
        
        if features is not None and 'anomaly' in self.ml_models:
            # Predict anomaly
            features_scaled = self.scaler.transform([features])
            anomaly_score = self.ml_models['anomaly'].decision_function(features_scaled)[0]
            
            if anomaly_score < -0.5:  # Anomaly threshold
                threats.append({
                    'type': 'anomaly',
                    'score': float(anomaly_score),
                    'severity': self.calculate_anomaly_severity(anomaly_score),
                    'confidence': min(abs(anomaly_score), 1.0),
                    'description': 'Unusual activity pattern detected'
                })
        
        return threats
    
    async def analyze_behavior(self, event: SecurityEvent) -> List[Dict[str, Any]]:
        """Analyze behavioral patterns"""
        threats = []
        
        # Get user/entity baseline
        entity_id = event.data.get('user_id') or event.data.get('system_id')
        
        if entity_id and entity_id in self.behavioral_baselines:
            baseline = self.behavioral_baselines[entity_id]
            
            # Check for deviations
            if deviation := await self.check_behavioral_deviation(event, baseline):
                threats.append({
                    'type': 'behavioral',
                    'deviation': deviation,
                    'severity': self.calculate_behavioral_severity(deviation),
                    'confidence': deviation['confidence'],
                    'description': f"Unusual behavior: {deviation['description']}"
                })
        
        return threats
    
    async def ml_detection(self, event: SecurityEvent) -> List[Dict[str, Any]]:
        """Use deep learning for threat detection"""
        threats = []
        
        if 'deep_learning' in self.ml_models:
            # Prepare input
            input_data = await self.prepare_dl_input(event)
            
            # Predict
            predictions = self.ml_models['deep_learning'].predict(input_data)
            
            # Interpret predictions
            for i, pred in enumerate(predictions[0]):
                if pred > 0.7:  # Threat threshold
                    threat_type = self.get_threat_class(i)
                    threats.append({
                        'type': 'ml_detection',
                        'threat_class': threat_type,
                        'probability': float(pred),
                        'severity': self.ml_severity_mapping(pred),
                        'confidence': float(pred),
                        'description': f"ML detected: {threat_type}"
                    })
        
        return threats
    
    async def threat_intel_matching(self, event: SecurityEvent) -> List[Dict[str, Any]]:
        """Match against threat intelligence"""
        threats = []
        
        for indicator in event.indicators:
            # Check threat intelligence database
            if threat_info := await self.lookup_threat_intel(indicator):
                threats.append({
                    'type': 'threat_intel',
                    'indicator': indicator,
                    'threat_info': threat_info,
                    'severity': threat_info['severity'],
                    'confidence': threat_info['confidence'],
                    'description': f"Known threat: {threat_info['description']}"
                })
        
        return threats
    
    async def ai_threat_analysis(self, event: SecurityEvent) -> List[Dict[str, Any]]:
        """Use AI for advanced threat analysis"""
        threats = []
        
        # Prepare context for AI
        context = {
            'event': event.data,
            'indicators': event.indicators,
            'context': event.context,
            'recent_events': await self.get_recent_related_events(event)
        }
        
        # AI analysis prompt
        prompt = f"""
        Analyze this security event for potential threats:
        
        Event Type: {event.event_type}
        Source: {event.source}
        Data: {json.dumps(context, indent=2)}
        
        Identify:
        1. Potential threats or attacks
        2. Attack patterns or techniques (MITRE ATT&CK)
        3. Risk level and impact
        4. Recommended response actions
        
        Format response as JSON with: threat_type, attack_technique, severity, confidence, description, recommendations
        """
        
        try:
            response = await self.call_ai_model(prompt)
            ai_analysis = json.loads(response)
            
            if ai_analysis.get('threat_type') != 'none':
                threats.append({
                    'type': 'ai_analysis',
                    'analysis': ai_analysis,
                    'severity': ThreatSeverity(ai_analysis['severity']),
                    'confidence': ai_analysis['confidence'],
                    'description': ai_analysis['description']
                })
                
        except Exception as e:
            logger.error(f"AI threat analysis failed: {e}")
        
        return threats
    
    async def correlate_to_incident(self, 
                                  event: SecurityEvent, 
                                  threats: List[Dict[str, Any]]) -> SecurityIncident:
        """Correlate event to existing or new incident"""
        
        # Check for existing incidents
        existing_incident = await self.find_related_incident(event, threats)
        
        if existing_incident:
            # Update existing incident
            existing_incident.timeline.append(event)
            existing_incident.severity = self.update_incident_severity(
                existing_incident.severity,
                max(t['severity'] for t in threats)
            )
            
            await self.update_incident(existing_incident)
            return existing_incident
        
        # Create new incident
        incident = SecurityIncident(
            id=self.generate_incident_id(),
            severity=max(t['severity'] for t in threats),
            title=await self.generate_incident_title(event, threats),
            description=await self.generate_incident_description(event, threats),
            affected_assets=await self.identify_affected_assets(event),
            indicators=[
                ThreatIndicator(
                    type=self.identify_indicator_type(ind),
                    value=ind,
                    threat_type=threats[0]['type'],
                    confidence=threats[0]['confidence'],
                    source=event.source,
                    last_seen=event.timestamp
                )
                for ind in event.indicators
            ],
            timeline=[event]
        )
        
        await self.store_incident(incident)
        self.active_incidents.inc()
        
        return incident
    
    async def trigger_response(self, incident: SecurityIncident):
        """Trigger automated response actions"""
        
        logger.info(f"Triggering response for incident {incident.id}")
        
        response_start = datetime.now()
        
        try:
            # Determine response strategy
            response_plan = await self.create_response_plan(incident)
            
            # Execute response actions
            for action in response_plan.actions:
                try:
                    result = await self.execute_response_action(action, incident)
                    incident.response_actions.append({
                        'action': action.type,
                        'timestamp': datetime.now().isoformat(),
                        'result': result,
                        'status': 'success'
                    })
                    
                except Exception as e:
                    logger.error(f"Response action failed: {action.type}", error=str(e))
                    incident.response_actions.append({
                        'action': action.type,
                        'timestamp': datetime.now().isoformat(),
                        'error': str(e),
                        'status': 'failed'
                    })
            
            # Update incident status
            if all(a['status'] == 'success' for a in incident.response_actions):
                incident.status = 'contained'
            else:
                incident.status = 'partially_contained'
            
            await self.update_incident(incident)
            
        finally:
            response_duration = (datetime.now() - response_start).total_seconds()
            self.incident_response_time.observe(response_duration)
    
    async def create_response_plan(self, incident: SecurityIncident) -> 'ResponsePlan':
        """Create automated response plan"""
        
        # Use AI to determine best response
        prompt = f"""
        Create a response plan for this security incident:
        
        Severity: {incident.severity.value}
        Type: {incident.title}
        Description: {incident.description}
        Affected Assets: {incident.affected_assets}
        Indicators: {[ind.value for ind in incident.indicators]}
        
        Consider:
        1. Immediate containment actions
        2. Investigation needs
        3. Recovery steps
        4. Prevention measures
        
        Provide a prioritized list of response actions.
        """
        
        ai_response = await self.call_ai_model(prompt)
        
        # Parse and validate response plan
        response_plan = ResponsePlan(incident_id=incident.id)
        
        # Add standard response actions based on severity
        if incident.severity == ThreatSeverity.CRITICAL:
            response_plan.add_action(ResponseAction(
                type='isolate_systems',
                priority=1,
                parameters={'systems': incident.affected_assets}
            ))
            response_plan.add_action(ResponseAction(
                type='block_indicators',
                priority=2,
                parameters={'indicators': [ind.value for ind in incident.indicators]}
            ))
            response_plan.add_action(ResponseAction(
                type='notify_security_team',
                priority=3,
                parameters={'urgency': 'immediate'}
            ))
        
        # Add AI-suggested actions
        # ... parse AI response and add custom actions
        
        return response_plan
    
    async def execute_response_action(self, 
                                    action: 'ResponseAction', 
                                    incident: SecurityIncident) -> Dict[str, Any]:
        """Execute a specific response action"""
        
        logger.info(f"Executing response action: {action.type}")
        
        # Action handlers
        action_handlers = {
            'isolate_systems': self.isolate_systems,
            'block_indicators': self.block_indicators,
            'disable_accounts': self.disable_accounts,
            'patch_vulnerabilities': self.patch_vulnerabilities,
            'update_rules': self.update_security_rules,
            'collect_forensics': self.collect_forensics,
            'notify_security_team': self.notify_security_team,
            'create_ticket': self.create_security_ticket
        }
        
        handler = action_handlers.get(action.type)
        if not handler:
            raise ValueError(f"Unknown action type: {action.type}")
        
        return await handler(action.parameters, incident)
    
    # Response action implementations
    async def isolate_systems(self, params: Dict[str, Any], incident: SecurityIncident) -> Dict[str, Any]:
        """Isolate affected systems from network"""
        
        results = []
        for system in params['systems']:
            try:
                # Call endpoint protection API
                isolation_result = await self.edr_client.isolate_host(system)
                
                # Update firewall rules
                await self.update_firewall_rules(system, action='block_all')
                
                results.append({
                    'system': system,
                    'status': 'isolated',
                    'timestamp': datetime.now().isoformat()
                })
                
            except Exception as e:
                results.append({
                    'system': system,
                    'status': 'failed',
                    'error': str(e)
                })
        
        return {'isolated_systems': results}
    
    async def block_indicators(self, params: Dict[str, Any], incident: SecurityIncident) -> Dict[str, Any]:
        """Block malicious indicators across security controls"""
        
        blocked = []
        
        for indicator in params['indicators']:
            indicator_type = self.identify_indicator_type(indicator)
            
            if indicator_type == 'ip':
                # Block at firewall
                await self.firewall_client.block_ip(indicator)
                # Block at WAF
                await self.waf_client.block_ip(indicator)
                
            elif indicator_type == 'domain':
                # Block at DNS
                await self.dns_security.block_domain(indicator)
                # Update proxy
                await self.proxy_client.block_domain(indicator)
                
            elif indicator_type == 'hash':
                # Block at endpoint
                await self.edr_client.block_hash(indicator)
                
            elif indicator_type == 'email':
                # Block at email gateway
                await self.email_security.block_sender(indicator)
            
            blocked.append(indicator)
        
        return {'blocked_indicators': blocked}
    
    # Helper methods
    def generate_event_id(self) -> str:
        """Generate unique event ID"""
        return f"evt_{datetime.now().timestamp()}_{hashlib.md5(str(datetime.now()).encode()).hexdigest()[:8]}"
    
    def generate_incident_id(self) -> str:
        """Generate unique incident ID"""
        return f"inc_{datetime.now().strftime('%Y%m%d')}_{hashlib.md5(str(datetime.now()).encode()).hexdigest()[:6]}"
    
    def is_ip_address(self, value: str) -> bool:
        """Check if value is an IP address"""
        ip_pattern = r'^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$'
        return bool(re.match(ip_pattern, value))
    
    def identify_indicator_type(self, indicator: str) -> str:
        """Identify the type of indicator"""
        if self.is_ip_address(indicator):
            return 'ip'
        elif re.match(r'^[a-fA-F0-9]{32}$', indicator):
            return 'hash_md5'
        elif re.match(r'^[a-fA-F0-9]{64}$', indicator):
            return 'hash_sha256'
        elif '@' in indicator:
            return 'email'
        elif indicator.startswith('http'):
            return 'url'
        else:
            return 'domain'
    
    async def call_ai_model(self, prompt: str) -> str:
        """Call AI model for analysis"""
        response = openai.ChatCompletion.create(
            model="gpt-4",
            messages=[
                {"role": "system", "content": "You are a security analyst AI assistant."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.3,
            max_tokens=1000
        )
        return response.choices[0].message.content
    
    async def close(self):
        """Cleanup resources"""
        if self.db_pool:
            await self.db_pool.close()
        await self.es_client.close()


class ResponseAction:
    """Response action definition"""
    def __init__(self, type: str, priority: int, parameters: Dict[str, Any]):
        self.type = type
        self.priority = priority
        self.parameters = parameters


class ResponsePlan:
    """Incident response plan"""
    def __init__(self, incident_id: str):
        self.incident_id = incident_id
        self.actions: List[ResponseAction] = []
        
    def add_action(self, action: ResponseAction):
        """Add action to plan"""
        self.actions.append(action)
        self.actions.sort(key=lambda x: x.priority)
```

### Step 2: Create Compliance Automation Agent

Create `agents/compliance_agent.py`:
```python
import asyncio
from typing import Dict, List, Any, Optional
from datetime import datetime, timedelta
from dataclasses import dataclass, field
import json
import structlog
from enum import Enum

logger = structlog.get_logger()

class ComplianceFramework(Enum):
    SOC2 = "SOC2"
    ISO27001 = "ISO27001"
    GDPR = "GDPR"
    HIPAA = "HIPAA"
    PCI_DSS = "PCI-DSS"
    NIST = "NIST"

@dataclass
class ComplianceControl:
    """Compliance control definition"""
    id: str
    framework: ComplianceFramework
    name: str
    description: str
    category: str
    automated: bool
    check_function: Optional[str] = None
    evidence_required: List[str] = field(default_factory=list)
    frequency: str = "daily"  # daily, weekly, monthly, continuous

@dataclass
class ComplianceCheck:
    """Result of compliance check"""
    control_id: str
    timestamp: datetime
    status: str  # compliant, non_compliant, partial, not_applicable
    evidence: Dict[str, Any]
    findings: List[str]
    remediation: Optional[str] = None

class ComplianceAutomationAgent:
    """Automated compliance monitoring and reporting"""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.controls: Dict[str, ComplianceControl] = {}
        self.check_results: List[ComplianceCheck] = []
        self.compliance_status: Dict[str, Any] = {}
        
    async def initialize(self):
        """Initialize compliance agent"""
        logger.info("Initializing Compliance Automation Agent")
        
        # Load compliance controls
        await self.load_compliance_controls()
        
        # Initialize continuous monitoring
        asyncio.create_task(self.continuous_compliance_monitoring())
    
    async def load_compliance_controls(self):
        """Load compliance control definitions"""
        
        # Example SOC2 controls
        self.controls['SOC2-CC6.1'] = ComplianceControl(
            id='SOC2-CC6.1',
            framework=ComplianceFramework.SOC2,
            name='Logical Access Controls',
            description='The entity implements logical access security software, infrastructure, and architectures',
            category='Common Criteria',
            automated=True,
            check_function='check_access_controls',
            evidence_required=['access_logs', 'user_permissions', 'authentication_config'],
            frequency='continuous'
        )
        
        self.controls['SOC2-CC7.2'] = ComplianceControl(
            id='SOC2-CC7.2',
            framework=ComplianceFramework.SOC2,
            name='System Monitoring',
            description='The entity monitors system components for anomalies',
            category='Common Criteria',
            automated=True,
            check_function='check_system_monitoring',
            evidence_required=['monitoring_config', 'alert_logs', 'incident_reports'],
            frequency='continuous'
        )
        
        # GDPR controls
        self.controls['GDPR-ART32'] = ComplianceControl(
            id='GDPR-ART32',
            framework=ComplianceFramework.GDPR,
            name='Security of Processing',
            description='Implementation of appropriate technical and organizational measures',
            category='Security',
            automated=True,
            check_function='check_data_security',
            evidence_required=['encryption_status', 'access_controls', 'security_policies'],
            frequency='weekly'
        )
    
    async def continuous_compliance_monitoring(self):
        """Continuously monitor compliance status"""
        
        while True:
            try:
                # Run scheduled checks
                await self.run_scheduled_checks()
                
                # Generate compliance dashboard
                await self.update_compliance_dashboard()
                
                # Check for compliance alerts
                await self.check_compliance_alerts()
                
                await asyncio.sleep(300)  # Check every 5 minutes
                
            except Exception as e:
                logger.error(f"Compliance monitoring error: {e}")
    
    async def run_scheduled_checks(self):
        """Run scheduled compliance checks"""
        
        current_time = datetime.now()
        
        for control_id, control in self.controls.items():
            if self.should_run_check(control, current_time):
                try:
                    result = await self.run_compliance_check(control)
                    self.check_results.append(result)
                    
                    # Take action on non-compliance
                    if result.status == 'non_compliant':
                        await self.handle_non_compliance(control, result)
                        
                except Exception as e:
                    logger.error(f"Compliance check failed for {control_id}: {e}")
    
    async def run_compliance_check(self, control: ComplianceControl) -> ComplianceCheck:
        """Execute a compliance check"""
        
        logger.info(f"Running compliance check: {control.id}")
        
        # Get check function
        check_func = getattr(self, control.check_function, None)
        if not check_func:
            raise ValueError(f"Unknown check function: {control.check_function}")
        
        # Collect evidence
        evidence = await self.collect_evidence(control.evidence_required)
        
        # Run check
        status, findings = await check_func(control, evidence)
        
        # Generate remediation if needed
        remediation = None
        if status == 'non_compliant':
            remediation = await self.generate_remediation(control, findings)
        
        return ComplianceCheck(
            control_id=control.id,
            timestamp=datetime.now(),
            status=status,
            evidence=evidence,
            findings=findings,
            remediation=remediation
        )
    
    async def check_access_controls(self, 
                                  control: ComplianceControl, 
                                  evidence: Dict[str, Any]) -> tuple[str, List[str]]:
        """Check logical access controls"""
        
        findings = []
        compliant = True
        
        # Check MFA enforcement
        if not evidence.get('mfa_enabled', False):
            findings.append("Multi-factor authentication not enforced for all users")
            compliant = False
        
        # Check password policy
        password_policy = evidence.get('password_policy', {})
        if password_policy.get('min_length', 0) < 12:
            findings.append("Password minimum length below requirement (12 characters)")
            compliant = False
        
        # Check privileged access
        privileged_users = evidence.get('privileged_users', [])
        for user in privileged_users:
            if not user.get('last_review_date'):
                findings.append(f"Privileged user {user['username']} access not reviewed")
                compliant = False
        
        # Check inactive accounts
        inactive_accounts = evidence.get('inactive_accounts', [])
        if inactive_accounts:
            findings.append(f"Found {len(inactive_accounts)} inactive accounts")
            compliant = False
        
        status = 'compliant' if compliant else 'non_compliant'
        return status, findings
    
    async def check_system_monitoring(self,
                                    control: ComplianceControl,
                                    evidence: Dict[str, Any]) -> tuple[str, List[str]]:
        """Check system monitoring capabilities"""
        
        findings = []
        compliant = True
        
        # Check monitoring coverage
        monitored_systems = evidence.get('monitored_systems', [])
        total_systems = evidence.get('total_systems', 0)
        
        coverage = len(monitored_systems) / total_systems if total_systems > 0 else 0
        if coverage < 0.95:
            findings.append(f"Monitoring coverage only {coverage*100:.1f}% (requires 95%)")
            compliant = False
        
        # Check alert configuration
        alert_rules = evidence.get('alert_rules', [])
        required_alerts = ['unauthorized_access', 'privilege_escalation', 'data_exfiltration']
        
        for required in required_alerts:
            if not any(rule['type'] == required for rule in alert_rules):
                findings.append(f"Missing alert rule for: {required}")
                compliant = False
        
        # Check log retention
        log_retention_days = evidence.get('log_retention_days', 0)
        if log_retention_days < 90:
            findings.append(f"Log retention {log_retention_days} days (requires 90)")
            compliant = False
        
        status = 'compliant' if compliant else 'non_compliant'
        return status, findings
    
    async def check_data_security(self,
                                control: ComplianceControl,
                                evidence: Dict[str, Any]) -> tuple[str, List[str]]:
        """Check data security measures"""
        
        findings = []
        compliant = True
        
        # Check encryption at rest
        unencrypted_data = evidence.get('unencrypted_data_stores', [])
        if unencrypted_data:
            findings.append(f"Found {len(unencrypted_data)} unencrypted data stores")
            compliant = False
        
        # Check encryption in transit
        insecure_endpoints = evidence.get('insecure_endpoints', [])
        if insecure_endpoints:
            findings.append(f"Found {len(insecure_endpoints)} endpoints without TLS")
            compliant = False
        
        # Check data classification
        unclassified_data = evidence.get('unclassified_data_percentage', 0)
        if unclassified_data > 5:
            findings.append(f"{unclassified_data}% of data is unclassified")
            compliant = False
        
        status = 'compliant' if compliant else 'non_compliant'
        return status, findings
    
    async def collect_evidence(self, required_evidence: List[str]) -> Dict[str, Any]:
        """Collect evidence for compliance check"""
        
        evidence = {}
        
        for evidence_type in required_evidence:
            if evidence_type == 'access_logs':
                evidence['access_logs'] = await self.get_access_logs()
            elif evidence_type == 'user_permissions':
                evidence['user_permissions'] = await self.get_user_permissions()
            elif evidence_type == 'authentication_config':
                evidence['authentication_config'] = await self.get_auth_config()
            elif evidence_type == 'monitoring_config':
                evidence['monitoring_config'] = await self.get_monitoring_config()
            # ... more evidence collectors
        
        return evidence
    
    async def handle_non_compliance(self, 
                                  control: ComplianceControl, 
                                  result: ComplianceCheck):
        """Handle non-compliance findings"""
        
        logger.warning(f"Non-compliance detected: {control.id}", findings=result.findings)
        
        # Create incident ticket
        ticket = await self.create_compliance_ticket(control, result)
        
        # Attempt auto-remediation if possible
        if result.remediation and control.automated:
            await self.attempt_auto_remediation(control, result)
        
        # Send notifications
        await self.send_compliance_alert(control, result, ticket)
        
        # Update compliance metrics
        await self.update_compliance_metrics(control, result)
    
    async def generate_remediation(self, 
                                 control: ComplianceControl,
                                 findings: List[str]) -> str:
        """Generate remediation plan using AI"""
        
        prompt = f"""
        Generate a remediation plan for these compliance findings:
        
        Control: {control.name} ({control.id})
        Framework: {control.framework.value}
        Findings:
        {json.dumps(findings, indent=2)}
        
        Provide specific, actionable steps to achieve compliance.
        """
        
        # Call AI model for remediation plan
        remediation = await self.call_ai_for_remediation(prompt)
        
        return remediation
    
    async def generate_compliance_report(self, 
                                       framework: ComplianceFramework) -> Dict[str, Any]:
        """Generate comprehensive compliance report"""
        
        # Filter controls by framework
        framework_controls = [c for c in self.controls.values() if c.framework == framework]
        
        # Get latest check results
        control_status = {}
        for control in framework_controls:
            latest_check = self.get_latest_check(control.id)
            control_status[control.id] = {
                'name': control.name,
                'status': latest_check.status if latest_check else 'not_checked',
                'last_checked': latest_check.timestamp.isoformat() if latest_check else None,
                'findings': latest_check.findings if latest_check else []
            }
        
        # Calculate compliance score
        compliant_count = sum(1 for s in control_status.values() if s['status'] == 'compliant')
        total_count = len(control_status)
        compliance_score = (compliant_count / total_count * 100) if total_count > 0 else 0
        
        return {
            'framework': framework.value,
            'report_date': datetime.now().isoformat(),
            'compliance_score': compliance_score,
            'total_controls': total_count,
            'compliant_controls': compliant_count,
            'non_compliant_controls': total_count - compliant_count,
            'control_status': control_status,
            'executive_summary': await self.generate_executive_summary(framework, compliance_score),
            'recommendations': await self.generate_recommendations(control_status)
        }
    
    def get_latest_check(self, control_id: str) -> Optional[ComplianceCheck]:
        """Get latest check result for control"""
        checks = [c for c in self.check_results if c.control_id == control_id]
        return max(checks, key=lambda x: x.timestamp) if checks else None
    
    def should_run_check(self, control: ComplianceControl, current_time: datetime) -> bool:
        """Determine if check should run based on frequency"""
        latest_check = self.get_latest_check(control.id)
        
        if not latest_check:
            return True
        
        time_since_last = current_time - latest_check.timestamp
        
        if control.frequency == 'continuous':
            return True
        elif control.frequency == 'daily':
            return time_since_last > timedelta(days=1)
        elif control.frequency == 'weekly':
            return time_since_last > timedelta(weeks=1)
        elif control.frequency == 'monthly':
            return time_since_last > timedelta(days=30)
        
        return False
```

### Step 3: Create Threat Hunting Agent

Create `agents/threat_hunting_agent.py`:
```python
import asyncio
from typing import Dict, List, Any, Optional, Set
from datetime import datetime, timedelta
from dataclasses import dataclass, field
import json
import networkx as nx
import pandas as pd
import numpy as np
from sklearn.cluster import DBSCAN
from sklearn.ensemble import RandomForestClassifier
import structlog

logger = structlog.get_logger()

@dataclass
class HuntHypothesis:
    """Threat hunting hypothesis"""
    id: str
    name: str
    description: str
    tactics: List[str]  # MITRE ATT&CK tactics
    techniques: List[str]  # MITRE ATT&CK techniques
    indicators: List[str]
    data_sources: List[str]
    priority: int
    created_date: datetime

@dataclass
class HuntLead:
    """Lead discovered during hunting"""
    id: str
    hypothesis_id: str
    confidence: float
    evidence: List[Dict[str, Any]]
    affected_entities: List[str]
    timeline: List[Dict[str, Any]]
    status: str  # investigating, confirmed, false_positive

class ThreatHuntingAgent:
    """Proactive threat hunting agent"""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.hypotheses: List[HuntHypothesis] = []
        self.active_hunts: Dict[str, Any] = {}
        self.hunt_results: List[HuntLead] = []
        self.attack_graph = nx.DiGraph()
        self.ml_models = {}
        
    async def initialize(self):
        """Initialize threat hunting agent"""
        logger.info("Initializing Threat Hunting Agent")
        
        # Load hunting hypotheses
        await self.load_hypotheses()
        
        # Load ML models for hunting
        await self.load_hunting_models()
        
        # Start proactive hunting
        asyncio.create_task(self.proactive_hunting_loop())
    
    async def load_hypotheses(self):
        """Load threat hunting hypotheses"""
        
        # Example hypotheses based on common threats
        self.hypotheses.extend([
            HuntHypothesis(
                id="HUNT-001",
                name="Lateral Movement Detection",
                description="Hunt for signs of lateral movement using compromised credentials",
                tactics=["TA0008"],  # Lateral Movement
                techniques=["T1021", "T1076"],  # Remote Services, RDP
                indicators=[
                    "Unusual RDP connections",
                    "Service account usage from workstations",
                    "Pass-the-hash indicators"
                ],
                data_sources=["windows_security_logs", "network_flows", "authentication_logs"],
                priority=1,
                created_date=datetime.now()
            ),
            HuntHypothesis(
                id="HUNT-002",
                name="Data Exfiltration",
                description="Hunt for data exfiltration attempts",
                tactics=["TA0010"],  # Exfiltration
                techniques=["T1048", "T1041"],  # Exfiltration Over Alternative Protocol
                indicators=[
                    "Large data transfers to external IPs",
                    "Unusual DNS queries",
                    "Encrypted traffic to suspicious domains"
                ],
                data_sources=["network_flows", "dns_logs", "proxy_logs"],
                priority=1,
                created_date=datetime.now()
            ),
            HuntHypothesis(
                id="HUNT-003",
                name="Persistence Mechanisms",
                description="Hunt for malicious persistence mechanisms",
                tactics=["TA0003"],  # Persistence
                techniques=["T1053", "T1543"],  # Scheduled Task, Services
                indicators=[
                    "New scheduled tasks",
                    "Service modifications",
                    "Registry run key changes"
                ],
                data_sources=["windows_event_logs", "sysmon_logs", "registry_monitoring"],
                priority=2,
                created_date=datetime.now()
            )
        ])
    
    async def proactive_hunting_loop(self):
        """Main hunting loop"""
        
        while True:
            try:
                # Select hypothesis to hunt
                hypothesis = await self.select_hypothesis()
                
                if hypothesis:
                    # Execute hunt
                    logger.info(f"Starting hunt: {hypothesis.name}")
                    leads = await self.execute_hunt(hypothesis)
                    
                    # Process leads
                    for lead in leads:
                        await self.investigate_lead(lead)
                
                # AI-driven hunting
                await self.ai_driven_hunting()
                
                # Update attack graph
                await self.update_attack_graph()
                
                await asyncio.sleep(1800)  # Hunt every 30 minutes
                
            except Exception as e:
                logger.error(f"Hunting error: {e}")
    
    async def select_hypothesis(self) -> Optional[HuntHypothesis]:
        """Select next hypothesis to hunt"""
        
        # Prioritize based on:
        # 1. Priority level
        # 2. Time since last hunt
        # 3. Current threat landscape
        
        available_hypotheses = []
        
        for hypothesis in self.hypotheses:
            last_hunt = self.active_hunts.get(hypothesis.id, {}).get('last_run')
            
            if not last_hunt or (datetime.now() - last_hunt) > timedelta(hours=24):
                # Calculate dynamic priority
                threat_score = await self.calculate_threat_score(hypothesis)
                available_hypotheses.append((hypothesis, threat_score))
        
        if available_hypotheses:
            # Sort by combined score
            available_hypotheses.sort(key=lambda x: x[0].priority * x[1], reverse=True)
            return available_hypotheses[0][0]
        
        return None
    
    async def execute_hunt(self, hypothesis: HuntHypothesis) -> List[HuntLead]:
        """Execute a specific hunt"""
        
        leads = []
        
        # Record hunt start
        self.active_hunts[hypothesis.id] = {
            'last_run': datetime.now(),
            'status': 'running'
        }
        
        # Collect data from required sources
        hunt_data = await self.collect_hunt_data(hypothesis.data_sources)
        
        # Apply detection logic
        for technique in hypothesis.techniques:
            technique_leads = await self.hunt_for_technique(
                technique,
                hunt_data,
                hypothesis
            )
            leads.extend(technique_leads)
        
        # ML-based anomaly detection
        ml_leads = await self.ml_based_hunting(hunt_data, hypothesis)
        leads.extend(ml_leads)
        
        # Update hunt status
        self.active_hunts[hypothesis.id]['status'] = 'completed'
        self.active_hunts[hypothesis.id]['leads_found'] = len(leads)
        
        return leads
    
    async def hunt_for_technique(self,
                               technique: str,
                               data: Dict[str, Any],
                               hypothesis: HuntHypothesis) -> List[HuntLead]:
        """Hunt for specific MITRE technique"""
        
        leads = []
        
        # Technique-specific detection logic
        if technique == "T1021":  # Remote Services
            leads.extend(await self.detect_remote_services_abuse(data))
        elif technique == "T1076":  # Remote Desktop Protocol
            leads.extend(await self.detect_rdp_abuse(data))
        elif technique == "T1048":  # Exfiltration Over Alternative Protocol
            leads.extend(await self.detect_data_exfiltration(data))
        elif technique == "T1053":  # Scheduled Task/Job
            leads.extend(await self.detect_scheduled_task_abuse(data))
        # ... more techniques
        
        # Tag leads with hypothesis
        for lead in leads:
            lead.hypothesis_id = hypothesis.id
        
        return leads
    
    async def detect_lateral_movement(self, data: Dict[str, Any]) -> List[HuntLead]:
        """Detect lateral movement patterns"""
        
        leads = []
        
        # Analyze authentication logs
        auth_logs = data.get('authentication_logs', [])
        
        # Build user behavior profiles
        user_profiles = await self.build_user_profiles(auth_logs)
        
        # Detect anomalies
        for user, profile in user_profiles.items():
            # Check for unusual authentication patterns
            if anomalies := await self.detect_auth_anomalies(user, profile):
                lead = HuntLead(
                    id=f"LEAD-LM-{datetime.now().timestamp()}",
                    hypothesis_id="",  # Set by caller
                    confidence=anomalies['confidence'],
                    evidence=anomalies['evidence'],
                    affected_entities=[user],
                    timeline=anomalies['timeline'],
                    status='investigating'
                )
                leads.append(lead)
        
        # Graph-based analysis
        auth_graph = await self.build_authentication_graph(auth_logs)
        graph_anomalies = await self.analyze_auth_graph(auth_graph)
        
        for anomaly in graph_anomalies:
            lead = HuntLead(
                id=f"LEAD-LM-GRAPH-{datetime.now().timestamp()}",
                hypothesis_id="",
                confidence=anomaly['confidence'],
                evidence=[anomaly],
                affected_entities=anomaly['entities'],
                timeline=anomaly['timeline'],
                status='investigating'
            )
            leads.append(lead)
        
        return leads
    
    async def ai_driven_hunting(self):
        """Use AI to discover new hunting opportunities"""
        
        # Get recent security events
        recent_events = await self.get_recent_security_events()
        
        # AI prompt for hunting ideas
        prompt = f"""
        Analyze these recent security events and suggest proactive threat hunting activities:
        
        Events summary:
        - Total events: {len(recent_events)}
        - Top event types: {self.summarize_event_types(recent_events)}
        - Unusual patterns: {await self.identify_unusual_patterns(recent_events)}
        
        Suggest:
        1. New hunting hypotheses based on observed patterns
        2. Specific queries or searches to run
        3. Correlations to investigate
        4. Behavioral patterns to monitor
        
        Format as JSON with: hypothesis_name, description, rationale, suggested_queries
        """
        
        ai_suggestions = await self.call_ai_model(prompt)
        
        # Create new hypotheses from AI suggestions
        for suggestion in ai_suggestions:
            hypothesis = HuntHypothesis(
                id=f"HUNT-AI-{datetime.now().timestamp()}",
                name=suggestion['hypothesis_name'],
                description=suggestion['description'],
                tactics=await self.map_to_mitre_tactics(suggestion),
                techniques=await self.map_to_mitre_techniques(suggestion),
                indicators=suggestion.get('indicators', []),
                data_sources=suggestion.get('data_sources', []),
                priority=3,  # AI-generated hunts get medium priority
                created_date=datetime.now()
            )
            
            self.hypotheses.append(hypothesis)
    
    async def investigate_lead(self, lead: HuntLead):
        """Deep investigation of a hunting lead"""
        
        logger.info(f"Investigating lead: {lead.id}")
        
        # Enrich lead with additional context
        lead = await self.enrich_lead(lead)
        
        # Determine if true positive
        verification = await self.verify_lead(lead)
        
        if verification['is_threat']:
            lead.status = 'confirmed'
            lead.confidence = verification['confidence']
            
            # Create security incident
            incident = await self.create_incident_from_lead(lead)
            
            # Trigger response
            await self.trigger_incident_response(incident)
        else:
            lead.status = 'false_positive'
            
            # Learn from false positive
            await self.learn_from_false_positive(lead)
        
        # Store investigation results
        self.hunt_results.append(lead)
    
    async def build_authentication_graph(self, auth_logs: List[Dict[str, Any]]) -> nx.DiGraph:
        """Build graph of authentication relationships"""
        
        graph = nx.DiGraph()
        
        for log in auth_logs:
            source = log.get('source_user')
            target = log.get('target_system')
            timestamp = log.get('timestamp')
            auth_type = log.get('auth_type')
            
            if source and target:
                # Add nodes
                if not graph.has_node(source):
                    graph.add_node(source, type='user')
                if not graph.has_node(target):
                    graph.add_node(target, type='system')
                
                # Add edge with attributes
                if graph.has_edge(source, target):
                    # Update edge attributes
                    graph[source][target]['count'] += 1
                    graph[source][target]['timestamps'].append(timestamp)
                else:
                    graph.add_edge(
                        source, target,
                        count=1,
                        timestamps=[timestamp],
                        auth_types=[auth_type]
                    )
        
        return graph
    
    async def analyze_auth_graph(self, graph: nx.DiGraph) -> List[Dict[str, Any]]:
        """Analyze authentication graph for anomalies"""
        
        anomalies = []
        
        # Detect unusual paths
        for node in graph.nodes():
            if graph.nodes[node].get('type') == 'user':
                # Check for unusual number of systems accessed
                out_degree = graph.out_degree(node)
                if out_degree > 10:  # Threshold
                    anomalies.append({
                        'type': 'excessive_system_access',
                        'user': node,
                        'systems_accessed': out_degree,
                        'confidence': min(out_degree / 10, 1.0),
                        'entities': [node] + list(graph.successors(node))
                    })
        
        # Detect privilege escalation paths
        admin_nodes = [n for n in graph.nodes() if 'admin' in n.lower()]
        for admin in admin_nodes:
            # Find all paths to admin
            for user in graph.nodes():
                if user != admin and graph.nodes[user].get('type') == 'user':
                    try:
                        paths = list(nx.all_simple_paths(graph, user, admin, cutoff=3))
                        if paths:
                            anomalies.append({
                                'type': 'potential_privilege_escalation',
                                'source': user,
                                'target': admin,
                                'paths': paths,
                                'confidence': 0.7,
                                'entities': [user, admin]
                            })
                    except nx.NetworkXNoPath:
                        pass
        
        return anomalies
    
    async def ml_based_hunting(self, 
                             data: Dict[str, Any],
                             hypothesis: HuntHypothesis) -> List[HuntLead]:
        """Machine learning based threat hunting"""
        
        leads = []
        
        # Prepare features
        features = await self.extract_ml_features(data)
        
        if features is not None and len(features) > 0:
            # Clustering for anomaly detection
            clustering = DBSCAN(eps=0.3, min_samples=5)
            clusters = clustering.fit_predict(features)
            
            # Find outliers (cluster -1)
            outlier_indices = np.where(clusters == -1)[0]
            
            for idx in outlier_indices:
                # Create lead for outlier
                lead = HuntLead(
                    id=f"LEAD-ML-{datetime.now().timestamp()}-{idx}",
                    hypothesis_id=hypothesis.id,
                    confidence=0.7,  # ML detections get moderate confidence
                    evidence=[{
                        'type': 'ml_anomaly',
                        'feature_vector': features[idx].tolist(),
                        'cluster': int(clusters[idx])
                    }],
                    affected_entities=await self.identify_entities_from_features(features[idx]),
                    timeline=[{'timestamp': datetime.now().isoformat(), 'event': 'ml_detection'}],
                    status='investigating'
                )
                leads.append(lead)
        
        return leads
    
    async def update_attack_graph(self):
        """Update knowledge graph of attack patterns"""
        
        # Add nodes for confirmed threats
        for lead in self.hunt_results:
            if lead.status == 'confirmed':
                # Add threat node
                threat_node = f"threat_{lead.id}"
                self.attack_graph.add_node(
                    threat_node,
                    type='threat',
                    confidence=lead.confidence,
                    timestamp=datetime.now().isoformat()
                )
                
                # Add technique nodes
                hypothesis = next((h for h in self.hypotheses if h.id == lead.hypothesis_id), None)
                if hypothesis:
                    for technique in hypothesis.techniques:
                        technique_node = f"technique_{technique}"
                        if not self.attack_graph.has_node(technique_node):
                            self.attack_graph.add_node(technique_node, type='technique')
                        
                        # Connect threat to technique
                        self.attack_graph.add_edge(threat_node, technique_node)
                
                # Add entity nodes
                for entity in lead.affected_entities:
                    entity_node = f"entity_{entity}"
                    if not self.attack_graph.has_node(entity_node):
                        self.attack_graph.add_node(entity_node, type='entity')
                    
                    # Connect threat to entity
                    self.attack_graph.add_edge(threat_node, entity_node)
        
        # Analyze graph for patterns
        await self.analyze_attack_patterns()
    
    async def generate_hunt_report(self) -> Dict[str, Any]:
        """Generate comprehensive hunting report"""
        
        # Calculate metrics
        total_hunts = len(self.active_hunts)
        total_leads = len(self.hunt_results)
        confirmed_threats = len([l for l in self.hunt_results if l.status == 'confirmed'])
        false_positives = len([l for l in self.hunt_results if l.status == 'false_positive'])
        
        # Top hypotheses by effectiveness
        hypothesis_effectiveness = {}
        for hypothesis in self.hypotheses:
            hypothesis_leads = [l for l in self.hunt_results if l.hypothesis_id == hypothesis.id]
            confirmed = len([l for l in hypothesis_leads if l.status == 'confirmed'])
            total = len(hypothesis_leads)
            
            if total > 0:
                hypothesis_effectiveness[hypothesis.id] = {
                    'name': hypothesis.name,
                    'effectiveness': confirmed / total,
                    'total_leads': total,
                    'confirmed_threats': confirmed
                }
        
        # Generate insights
        insights = await self.generate_hunting_insights()
        
        return {
            'report_date': datetime.now().isoformat(),
            'summary': {
                'total_hunts': total_hunts,
                'total_leads': total_leads,
                'confirmed_threats': confirmed_threats,
                'false_positives': false_positives,
                'detection_rate': confirmed_threats / total_leads if total_leads > 0 else 0
            },
            'hypothesis_effectiveness': hypothesis_effectiveness,
            'recent_threats': [
                {
                    'id': lead.id,
                    'hypothesis': lead.hypothesis_id,
                    'confidence': lead.confidence,
                    'affected_entities': lead.affected_entities,
                    'status': lead.status
                }
                for lead in self.hunt_results[-10:]
                if lead.status == 'confirmed'
            ],
            'insights': insights,
            'recommendations': await self.generate_hunting_recommendations()
        }
```

### Step 4: Create Security Orchestrator

Create `agents/security_orchestrator.py`:
```python
import asyncio
from typing import Dict, List, Any, Optional
from datetime import datetime
import json
import structlog
from dataclasses import dataclass
from enum import Enum

logger = structlog.get_logger()

class SecurityTaskType(Enum):
    DETECT = "detect"
    INVESTIGATE = "investigate"
    RESPOND = "respond"
    HUNT = "hunt"
    COMPLY = "comply"
    REPORT = "report"

@dataclass
class SecurityTask:
    """Security task for agents"""
    id: str
    type: SecurityTaskType
    priority: int
    data: Dict[str, Any]
    created_at: datetime
    assigned_agent: Optional[str] = None
    status: str = "pending"
    result: Optional[Dict[str, Any]] = None

class SecurityOrchestrator:
    """Orchestrate multiple security agents"""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.agents = {}
        self.task_queue: asyncio.Queue = asyncio.Queue()
        self.active_tasks: Dict[str, SecurityTask] = {}
        self.completed_tasks: List[SecurityTask] = []
        
    async def initialize(self):
        """Initialize orchestrator"""
        logger.info("Initializing Security Orchestrator")
        
        # Initialize all security agents
        await self.initialize_agents()
        
        # Start task processing
        asyncio.create_task(self.process_tasks())
        
        # Start coordination loop
        asyncio.create_task(self.coordination_loop())
    
    async def initialize_agents(self):
        """Initialize all security agents"""
        
        # Initialize Security Intelligence Engine
        from .security_agent import SecurityIntelligenceEngine
        self.agents['security_intelligence'] = SecurityIntelligenceEngine(self.config)
        await self.agents['security_intelligence'].initialize()
        
        # Initialize Compliance Agent
        from .compliance_agent import ComplianceAutomationAgent
        self.agents['compliance'] = ComplianceAutomationAgent(self.config)
        await self.agents['compliance'].initialize()
        
        # Initialize Threat Hunting Agent
        from .threat_hunting_agent import ThreatHuntingAgent
        self.agents['threat_hunting'] = ThreatHuntingAgent(self.config)
        await self.agents['threat_hunting'].initialize()
        
        logger.info(f"Initialized {len(self.agents)} security agents")
    
    async def process_tasks(self):
        """Process security tasks"""
        
        while True:
            try:
                # Get next task
                task = await self.task_queue.get()
                
                # Assign to appropriate agent
                agent = await self.select_agent(task)
                
                if agent:
                    task.assigned_agent = agent
                    task.status = "processing"
                    self.active_tasks[task.id] = task
                    
                    # Process task
                    result = await self.execute_task(task, agent)
                    
                    # Update task
                    task.result = result
                    task.status = "completed"
                    self.completed_tasks.append(task)
                    del self.active_tasks[task.id]
                    
                    # Handle task result
                    await self.handle_task_result(task)
                else:
                    logger.error(f"No agent available for task type: {task.type}")
                    
            except Exception as e:
                logger.error(f"Task processing error: {e}")
    
    async def coordination_loop(self):
        """Coordinate agent activities"""
        
        while True:
            try:
                # Check system health
                health = await self.check_system_health()
                
                # Coordinate based on current state
                if health['threat_level'] == 'critical':
                    await self.coordinate_crisis_response()
                elif health['compliance_score'] < 80:
                    await self.coordinate_compliance_improvement()
                else:
                    await self.coordinate_proactive_security()
                
                # Generate security dashboard
                await self.update_security_dashboard()
                
                await asyncio.sleep(60)  # Coordinate every minute
                
            except Exception as e:
                logger.error(f"Coordination error: {e}")
    
    async def submit_task(self, task: SecurityTask):
        """Submit task for processing"""
        await self.task_queue.put(task)
        logger.info(f"Task submitted: {task.id} ({task.type.value})")
    
    async def select_agent(self, task: SecurityTask) -> Optional[str]:
        """Select appropriate agent for task"""
        
        agent_mapping = {
            SecurityTaskType.DETECT: 'security_intelligence',
            SecurityTaskType.INVESTIGATE: 'security_intelligence',
            SecurityTaskType.RESPOND: 'security_intelligence',
            SecurityTaskType.HUNT: 'threat_hunting',
            SecurityTaskType.COMPLY: 'compliance',
            SecurityTaskType.REPORT: 'compliance'
        }
        
        return agent_mapping.get(task.type)
    
    async def execute_task(self, task: SecurityTask, agent_name: str) -> Dict[str, Any]:
        """Execute task with specified agent"""
        
        agent = self.agents[agent_name]
        
        if task.type == SecurityTaskType.DETECT:
            # Process security event
            event = task.data['event']
            threats = await agent.detect_threats(event)
            return {'threats': threats}
            
        elif task.type == SecurityTaskType.INVESTIGATE:
            # Investigate incident
            incident_id = task.data['incident_id']
            investigation = await agent.investigate_incident(incident_id)
            return {'investigation': investigation}
            
        elif task.type == SecurityTaskType.RESPOND:
            # Execute response
            incident = task.data['incident']
            response = await agent.trigger_response(incident)
            return {'response': response}
            
        elif task.type == SecurityTaskType.HUNT:
            # Execute hunt
            hypothesis = task.data['hypothesis']
            leads = await agent.execute_hunt(hypothesis)
            return {'leads': leads}
            
        elif task.type == SecurityTaskType.COMPLY:
            # Run compliance check
            framework = task.data['framework']
            report = await agent.generate_compliance_report(framework)
            return {'report': report}
            
        else:
            raise ValueError(f"Unknown task type: {task.type}")
    
    async def handle_task_result(self, task: SecurityTask):
        """Handle completed task result"""
        
        if task.type == SecurityTaskType.DETECT and task.result.get('threats'):
            # Create investigation tasks for detected threats
            for threat in task.result['threats']:
                if threat['confidence'] > 0.7:
                    investigate_task = SecurityTask(
                        id=f"TASK-INV-{datetime.now().timestamp()}",
                        type=SecurityTaskType.INVESTIGATE,
                        priority=threat['severity'].value,
                        data={'threat': threat},
                        created_at=datetime.now()
                    )
                    await self.submit_task(investigate_task)
        
        elif task.type == SecurityTaskType.INVESTIGATE:
            # Create response task if threat confirmed
            investigation = task.result.get('investigation', {})
            if investigation.get('confirmed'):
                respond_task = SecurityTask(
                    id=f"TASK-RESP-{datetime.now().timestamp()}",
                    type=SecurityTaskType.RESPOND,
                    priority=1,
                    data={'incident': investigation['incident']},
                    created_at=datetime.now()
                )
                await self.submit_task(respond_task)
    
    async def check_system_health(self) -> Dict[str, Any]:
        """Check overall security system health"""
        
        # Collect metrics from all agents
        health_metrics = {
            'threat_level': 'normal',
            'active_incidents': len(self.active_tasks),
            'compliance_score': 95,
            'hunting_coverage': 80,
            'response_readiness': 100
        }
        
        # Check for critical threats
        critical_tasks = [t for t in self.active_tasks.values() if t.priority == 1]
        if critical_tasks:
            health_metrics['threat_level'] = 'critical'
        
        # Get compliance status
        if 'compliance' in self.agents:
            compliance_status = await self.agents['compliance'].get_overall_compliance()
            health_metrics['compliance_score'] = compliance_status.get('score', 95)
        
        return health_metrics
    
    async def coordinate_crisis_response(self):
        """Coordinate response during security crisis"""
        
        logger.warning("Coordinating crisis response")
        
        # Pause non-critical activities
        await self.pause_non_critical_tasks()
        
        # Allocate all resources to threat response
        await self.prioritize_threat_response()
        
        # Enable enhanced monitoring
        await self.enable_enhanced_monitoring()
        
        # Notify security team
        await self.send_crisis_notification()
    
    async def coordinate_proactive_security(self):
        """Coordinate proactive security activities"""
        
        # Schedule threat hunting
        hunt_task = SecurityTask(
            id=f"TASK-HUNT-{datetime.now().timestamp()}",
            type=SecurityTaskType.HUNT,
            priority=3,
            data={'hypothesis': await self.select_hunt_hypothesis()},
            created_at=datetime.now()
        )
        await self.submit_task(hunt_task)
        
        # Schedule compliance checks
        compliance_task = SecurityTask(
            id=f"TASK-COMPLY-{datetime.now().timestamp()}",
            type=SecurityTaskType.COMPLY,
            priority=3,
            data={'framework': 'SOC2'},
            created_at=datetime.now()
        )
        await self.submit_task(compliance_task)
    
    async def generate_executive_report(self) -> Dict[str, Any]:
        """Generate executive security report"""
        
        # Collect data from all agents
        threat_summary = await self.agents['security_intelligence'].get_threat_summary()
        compliance_summary = await self.agents['compliance'].get_compliance_summary()
        hunting_summary = await self.agents['threat_hunting'].get_hunting_summary()
        
        # Calculate KPIs
        kpis = {
            'mean_time_to_detect': await self.calculate_mttd(),
            'mean_time_to_respond': await self.calculate_mttr(),
            'threat_prevention_rate': await self.calculate_prevention_rate(),
            'compliance_score': compliance_summary.get('overall_score', 0),
            'security_posture': await self.calculate_security_posture()
        }
        
        return {
            'report_date': datetime.now().isoformat(),
            'executive_summary': await self.generate_executive_summary(kpis),
            'kpis': kpis,
            'threat_landscape': threat_summary,
            'compliance_status': compliance_summary,
            'hunting_results': hunting_summary,
            'recommendations': await self.generate_recommendations(),
            'risk_assessment': await self.assess_current_risks()
        }
```

### Step 5: Create Main Security Operations Application

Create `main_security_ops.py`:
```python
#!/usr/bin/env python3
"""
AI Security Operations Center - Main Application
"""

import asyncio
import argparse
import sys
import os
from pathlib import Path
import json
import logging
from datetime import datetime
import signal

from agents.security_orchestrator import SecurityOrchestrator, SecurityTask, SecurityTaskType
from fastapi import FastAPI, WebSocket, HTTPException
from fastapi.responses import HTMLResponse
import uvicorn
import structlog

# Configure structured logging
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.dev.ConsoleRenderer()
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger()

class AISecurityOperationsCenter:
    """Main AI-powered Security Operations Center"""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.orchestrator = SecurityOrchestrator(config)
        self.app = FastAPI(title="AI Security Operations Center")
        self.setup_api_routes()
        self.running = False
        
    def setup_api_routes(self):
        """Setup FastAPI routes"""
        
        @self.app.get("/")
        async def root():
            return {"message": "AI Security Operations Center", "status": "operational"}
        
        @self.app.get("/health")
        async def health():
            """Health check endpoint"""
            health_status = await self.orchestrator.check_system_health()
            return health_status
        
        @self.app.post("/events")
        async def submit_event(event: Dict[str, Any]):
            """Submit security event for processing"""
            task = SecurityTask(
                id=f"TASK-EVT-{datetime.now().timestamp()}",
                type=SecurityTaskType.DETECT,
                priority=3,
                data={'event': event},
                created_at=datetime.now()
            )
            await self.orchestrator.submit_task(task)
            return {"task_id": task.id, "status": "submitted"}
        
        @self.app.get("/incidents")
        async def get_incidents():
            """Get active incidents"""
            active_incidents = [
                task for task in self.orchestrator.active_tasks.values()
                if task.type in [SecurityTaskType.INVESTIGATE, SecurityTaskType.RESPOND]
            ]
            return {"incidents": active_incidents}
        
        @self.app.get("/compliance/{framework}")
        async def get_compliance_status(framework: str):
            """Get compliance status for framework"""
            task = SecurityTask(
                id=f"TASK-COMP-{datetime.now().timestamp()}",
                type=SecurityTaskType.COMPLY,
                priority=3,
                data={'framework': framework},
                created_at=datetime.now()
            )
            await self.orchestrator.submit_task(task)
            
            # Wait for result (in production, use async job)
            await asyncio.sleep(5)
            
            if task.id in self.orchestrator.completed_tasks:
                return task.result
            else:
                return {"status": "processing", "task_id": task.id}
        
        @self.app.get("/hunt/status")
        async def get_hunt_status():
            """Get threat hunting status"""
            if 'threat_hunting' in self.orchestrator.agents:
                return await self.orchestrator.agents['threat_hunting'].generate_hunt_report()
            return {"error": "Threat hunting agent not available"}
        
        @self.app.get("/report/executive")
        async def get_executive_report():
            """Get executive security report"""
            return await self.orchestrator.generate_executive_report()
        
        @self.app.websocket("/ws/dashboard")
        async def websocket_dashboard(websocket: WebSocket):
            """WebSocket for real-time dashboard"""
            await websocket.accept()
            
            try:
                while True:
                    # Send real-time updates
                    dashboard_data = {
                        'timestamp': datetime.now().isoformat(),
                        'health': await self.orchestrator.check_system_health(),
                        'active_tasks': len(self.orchestrator.active_tasks),
                        'recent_threats': self.get_recent_threats(),
                        'metrics': await self.get_real_time_metrics()
                    }
                    
                    await websocket.send_json(dashboard_data)
                    await asyncio.sleep(5)  # Update every 5 seconds
                    
            except Exception as e:
                logger.error(f"WebSocket error: {e}")
            finally:
                await websocket.close()
    
    async def start(self):
        """Start the Security Operations Center"""
        logger.info("Starting AI Security Operations Center")
        
        self.running = True
        
        # Initialize orchestrator
        await self.orchestrator.initialize()
        
        # Start event processing
        asyncio.create_task(self.process_security_events())
        
        # Start API server
        config = uvicorn.Config(
            self.app,
            host=self.config.get('api_host', '0.0.0.0'),
            port=self.config.get('api_port', 8001),
            log_level="info"
        )
        server = uvicorn.Server(config)
        
        # Run server
        await server.serve()
    
    async def process_security_events(self):
        """Process incoming security events"""
        
        # In production, this would connect to real data sources
        # For demo, we'll simulate events
        
        event_sources = [
            self.simulate_network_events(),
            self.simulate_endpoint_events(),
            self.simulate_application_events()
        ]
        
        await asyncio.gather(*event_sources)
    
    async def simulate_network_events(self):
        """Simulate network security events"""
        
        while self.running:
            # Simulate various network events
            events = [
                {
                    'type': 'network_connection',
                    'source_ip': f"192.168.1.{np.random.randint(1, 255)}",
                    'dest_ip': f"10.0.0.{np.random.randint(1, 255)}",
                    'port': np.random.choice([22, 80, 443, 3389, 8080]),
                    'protocol': 'TCP',
                    'bytes': np.random.randint(100, 10000),
                    'timestamp': datetime.now().isoformat()
                },
                {
                    'type': 'dns_query',
                    'source_ip': f"192.168.1.{np.random.randint(1, 255)}",
                    'domain': np.random.choice([
                        'google.com',
                        'microsoft.com',
                        'suspicious-domain.com',
                        'malware-c2.com'
                    ]),
                    'timestamp': datetime.now().isoformat()
                }
            ]
            
            for event in events:
                if np.random.random() < 0.1:  # 10% chance of suspicious event
                    event['suspicious'] = True
                
                task = SecurityTask(
                    id=f"TASK-NET-{datetime.now().timestamp()}",
                    type=SecurityTaskType.DETECT,
                    priority=3,
                    data={'event': event},
                    created_at=datetime.now()
                )
                
                await self.orchestrator.submit_task(task)
            
            await asyncio.sleep(30)  # Generate events every 30 seconds
    
    async def simulate_endpoint_events(self):
        """Simulate endpoint security events"""
        
        while self.running:
            events = [
                {
                    'type': 'process_creation',
                    'hostname': f"WORKSTATION-{np.random.randint(1, 100)}",
                    'process_name': np.random.choice([
                        'chrome.exe',
                        'firefox.exe',
                        'powershell.exe',
                        'cmd.exe',
                        'suspicious.exe'
                    ]),
                    'parent_process': 'explorer.exe',
                    'command_line': 'sample command',
                    'user': f"user{np.random.randint(1, 50)}",
                    'timestamp': datetime.now().isoformat()
                }
            ]
            
            for event in events:
                task = SecurityTask(
                    id=f"TASK-EP-{datetime.now().timestamp()}",
                    type=SecurityTaskType.DETECT,
                    priority=3,
                    data={'event': event},
                    created_at=datetime.now()
                )
                
                await self.orchestrator.submit_task(task)
            
            await asyncio.sleep(45)
    
    async def simulate_application_events(self):
        """Simulate application security events"""
        
        while self.running:
            events = [
                {
                    'type': 'authentication',
                    'application': 'web_portal',
                    'user': f"user{np.random.randint(1, 100)}",
                    'source_ip': f"192.168.1.{np.random.randint(1, 255)}",
                    'status': np.random.choice(['success', 'failed']),
                    'timestamp': datetime.now().isoformat()
                }
            ]
            
            for event in events:
                task = SecurityTask(
                    id=f"TASK-APP-{datetime.now().timestamp()}",
                    type=SecurityTaskType.DETECT,
                    priority=3,
                    data={'event': event},
                    created_at=datetime.now()
                )
                
                await self.orchestrator.submit_task(task)
            
            await asyncio.sleep(60)
    
    def get_recent_threats(self) -> List[Dict[str, Any]]:
        """Get recent detected threats"""
        recent_tasks = self.orchestrator.completed_tasks[-10:]
        threats = []
        
        for task in recent_tasks:
            if task.type == SecurityTaskType.DETECT and task.result:
                task_threats = task.result.get('threats', [])
                threats.extend(task_threats)
        
        return threats[-5:]  # Return last 5 threats
    
    async def get_real_time_metrics(self) -> Dict[str, Any]:
        """Get real-time security metrics"""
        
        # Calculate metrics from completed tasks
        total_events = len([t for t in self.orchestrator.completed_tasks if t.type == SecurityTaskType.DETECT])
        threats_detected = len([t for t in self.orchestrator.completed_tasks 
                              if t.type == SecurityTaskType.DETECT and t.result and t.result.get('threats')])
        
        return {
            'events_processed': total_events,
            'threats_detected': threats_detected,
            'detection_rate': threats_detected / total_events if total_events > 0 else 0,
            'active_investigations': len([t for t in self.orchestrator.active_tasks.values() 
                                        if t.type == SecurityTaskType.INVESTIGATE]),
            'compliance_checks_today': len([t for t in self.orchestrator.completed_tasks 
                                          if t.type == SecurityTaskType.COMPLY and 
                                          t.created_at.date() == datetime.now().date()])
        }
    
    async def stop(self):
        """Stop the Security Operations Center"""
        logger.info("Stopping AI Security Operations Center")
        self.running = False
        
        # Clean up resources
        for agent in self.orchestrator.agents.values():
            if hasattr(agent, 'close'):
                await agent.close()


async def main():
    """Main entry point"""
    
    parser = argparse.ArgumentParser(
        description="AI Security Operations Center",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Start SOC with default config
  python main_security_ops.py
  
  # Start with custom config
  python main_security_ops.py --config config.json
  
  # Start in demo mode
  python main_security_ops.py --demo
        """
    )
    
    parser.add_argument('--config', default='config.json',
                       help='Configuration file')
    parser.add_argument('--demo', action='store_true',
                       help='Run in demo mode with simulated events')
    parser.add_argument('--port', type=int, default=8001,
                       help='API port (default: 8001)')
    
    args = parser.parse_args()
    
    # Load configuration
    config_path = Path(args.config)
    if config_path.exists():
        with open(config_path, 'r') as f:
            config = json.load(f)
    else:
        # Default configuration
        config = {
            'openai_api_key': os.getenv('OPENAI_API_KEY'),
            'elasticsearch_url': os.getenv('ELASTICSEARCH_URL', 'http://localhost:9200'),
            'database_url': os.getenv('DATABASE_URL', 'postgresql://user:pass@localhost/security'),
            'api_host': '0.0.0.0',
            'api_port': args.port,
            'demo_mode': args.demo
        }
    
    if not config.get('openai_api_key'):
        logger.error("❌ OpenAI API key not configured")
        sys.exit(1)
    
    # Create SOC
    soc = AISecurityOperationsCenter(config)
    
    # Setup signal handlers
    def signal_handler(sig, frame):
        logger.info("Received shutdown signal")
        asyncio.create_task(soc.stop())
        sys.exit(0)
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    try:
        # Start SOC
        await soc.start()
        
    except Exception as e:
        logger.error(f"SOC failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    # Required for numpy in simulate functions
    import numpy as np
    
    asyncio.run(main())
```

### Step 6: Create Dashboard

Create `dashboard/security_dashboard.html`:
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AI Security Operations Center</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        @keyframes pulse {
            0% { opacity: 1; }
            50% { opacity: 0.5; }
            100% { opacity: 1; }
        }
        .pulse { animation: pulse 2s infinite; }
        
        .threat-critical { @apply bg-red-500; }
        .threat-high { @apply bg-orange-500; }
        .threat-medium { @apply bg-yellow-500; }
        .threat-low { @apply bg-blue-500; }
        .threat-info { @apply bg-gray-500; }
    </style>
</head>
<body class="bg-gray-900 text-white">
    <div class="container mx-auto p-4">
        <header class="mb-8">
            <h1 class="text-4xl font-bold mb-2">AI Security Operations Center</h1>
            <div class="flex items-center space-x-4">
                <span id="status" class="flex items-center">
                    <div class="w-3 h-3 bg-green-500 rounded-full pulse mr-2"></div>
                    Operational
                </span>
                <span id="time" class="text-gray-400"></span>
            </div>
        </header>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
            <div class="bg-gray-800 p-6 rounded-lg">
                <h3 class="text-lg font-semibold mb-2">Threat Level</h3>
                <div id="threat-level" class="text-3xl font-bold text-green-500">NORMAL</div>
            </div>
            
            <div class="bg-gray-800 p-6 rounded-lg">
                <h3 class="text-lg font-semibold mb-2">Active Incidents</h3>
                <div id="active-incidents" class="text-3xl font-bold">0</div>
            </div>
            
            <div class="bg-gray-800 p-6 rounded-lg">
                <h3 class="text-lg font-semibold mb-2">Compliance Score</h3>
                <div id="compliance-score" class="text-3xl font-bold">95%</div>
            </div>
            
            <div class="bg-gray-800 p-6 rounded-lg">
                <h3 class="text-lg font-semibold mb-2">Detection Rate</h3>
                <div id="detection-rate" class="text-3xl font-bold">0%</div>
            </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
            <div class="bg-gray-800 p-6 rounded-lg">
                <h3 class="text-xl font-semibold mb-4">Recent Threats</h3>
                <div id="recent-threats" class="space-y-2">
                    <p class="text-gray-400">No threats detected</p>
                </div>
            </div>
            
            <div class="bg-gray-800 p-6 rounded-lg">
                <h3 class="text-xl font-semibold mb-4">Security Events Timeline</h3>
                <canvas id="events-chart"></canvas>
            </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <div class="bg-gray-800 p-6 rounded-lg">
                <h3 class="text-xl font-semibold mb-4">Agent Status</h3>
                <div id="agent-status" class="space-y-2">
                    <div class="flex justify-between">
                        <span>Security Intelligence</span>
                        <span class="text-green-500">Active</span>
                    </div>
                    <div class="flex justify-between">
                        <span>Threat Hunting</span>
                        <span class="text-green-500">Active</span>
                    </div>
                    <div class="flex justify-between">
                        <span>Compliance</span>
                        <span class="text-green-500">Active</span>
                    </div>
                </div>
            </div>
            
            <div class="bg-gray-800 p-6 rounded-lg">
                <h3 class="text-xl font-semibold mb-4">System Health</h3>
                <canvas id="health-chart"></canvas>
            </div>
            
            <div class="bg-gray-800 p-6 rounded-lg">
                <h3 class="text-xl font-semibold mb-4">Response Metrics</h3>
                <div class="space-y-2">
                    <div class="flex justify-between">
                        <span>MTTD</span>
                        <span id="mttd">-</span>
                    </div>
                    <div class="flex justify-between">
                        <span>MTTR</span>
                        <span id="mttr">-</span>
                    </div>
                    <div class="flex justify-between">
                        <span>Prevention Rate</span>
                        <span id="prevention-rate">-</span>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        // WebSocket connection
        const ws = new WebSocket('ws://localhost:8001/ws/dashboard');
        
        // Charts
        let eventsChart, healthChart;
        
        // Initialize charts
        function initCharts() {
            // Events timeline chart
            const eventsCtx = document.getElementById('events-chart').getContext('2d');
            eventsChart = new Chart(eventsCtx, {
                type: 'line',
                data: {
                    labels: [],
                    datasets: [{
                        label: 'Security Events',
                        data: [],
                        borderColor: 'rgb(59, 130, 246)',
                        tension: 0.1
                    }, {
                        label: 'Threats Detected',
                        data: [],
                        borderColor: 'rgb(239, 68, 68)',
                        tension: 0.1
                    }]
                },
                options: {
                    responsive: true,
                    scales: {
                        y: { beginAtZero: true }
                    },
                    plugins: {
                        legend: { position: 'bottom' }
                    }
                }
            });
            
            // System health chart
            const healthCtx = document.getElementById('health-chart').getContext('2d');
            healthChart = new Chart(healthCtx, {
                type: 'doughnut',
                data: {
                    labels: ['Healthy', 'Warning', 'Critical'],
                    datasets: [{
                        data: [95, 4, 1],
                        backgroundColor: [
                            'rgb(34, 197, 94)',
                            'rgb(251, 191, 36)',
                            'rgb(239, 68, 68)'
                        ]
                    }]
                },
                options: {
                    responsive: true,
                    plugins: {
                        legend: { position: 'bottom' }
                    }
                }
            });
        }
        
        // Update dashboard with WebSocket data
        ws.onmessage = function(event) {
            const data = JSON.parse(event.data);
            
            // Update metrics
            document.getElementById('threat-level').textContent = data.health.threat_level.toUpperCase();
            document.getElementById('threat-level').className = `text-3xl font-bold ${getThreatLevelColor(data.health.threat_level)}`;
            document.getElementById('active-incidents').textContent = data.health.active_incidents;
            document.getElementById('compliance-score').textContent = data.health.compliance_score + '%';
            document.getElementById('detection-rate').textContent = (data.metrics.detection_rate * 100).toFixed(1) + '%';
            
            // Update recent threats
            updateRecentThreats(data.recent_threats);
            
            // Update charts
            updateCharts(data);
            
            // Update time
            document.getElementById('time').textContent = new Date(data.timestamp).toLocaleString();
        };
        
        function getThreatLevelColor(level) {
            switch(level) {
                case 'critical': return 'text-red-500';
                case 'high': return 'text-orange-500';
                case 'medium': return 'text-yellow-500';
                case 'low': return 'text-blue-500';
                default: return 'text-green-500';
            }
        }
        
        function updateRecentThreats(threats) {
            const container = document.getElementById('recent-threats');
            
            if (threats.length === 0) {
                container.innerHTML = '<p class="text-gray-400">No threats detected</p>';
                return;
            }
            
            container.innerHTML = threats.map(threat => `
                <div class="flex items-center justify-between p-2 bg-gray-700 rounded">
                    <span>${threat.type || 'Unknown'}</span>
                    <span class="px-2 py-1 text-xs rounded threat-${threat.severity || 'info'}">${threat.severity || 'INFO'}</span>
                </div>
            `).join('');
        }
        
        function updateCharts(data) {
            // Update events chart
            const time = new Date(data.timestamp).toLocaleTimeString();
            eventsChart.data.labels.push(time);
            eventsChart.data.datasets[0].data.push(data.metrics.events_processed);
            eventsChart.data.datasets[1].data.push(data.metrics.threats_detected);
            
            // Keep only last 20 data points
            if (eventsChart.data.labels.length > 20) {
                eventsChart.data.labels.shift();
                eventsChart.data.datasets.forEach(dataset => dataset.data.shift());
            }
            
            eventsChart.update();
        }
        
        // Initialize on load
        initCharts();
        
        // Update time every second
        setInterval(() => {
            if (ws.readyState !== WebSocket.OPEN) {
                document.getElementById('status').innerHTML = '<div class="w-3 h-3 bg-red-500 rounded-full mr-2"></div>Disconnected';
            }
        }, 1000);
    </script>
</body>
</html>
```

## 🏃 Running the Exercise

1. **Set up environment:**
```bash
# Navigate to exercise directory
cd exercises/exercise2-ai-security-ops

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

Create `requirements.txt`:
```txt
# Core dependencies
aiohttp==3.9.3
asyncio==3.4.3
fastapi==0.109.2
uvicorn==0.27.1
websockets==12.0

# AI/ML
openai==1.12.0
langchain==0.1.9
tensorflow==2.15.0
scikit-learn==1.4.0
numpy==1.26.3
pandas==2.2.0

# Security tools
yara-python==4.3.1
elasticsearch==8.12.1
asyncpg==0.29.0

# Monitoring
prometheus-client==0.19.0
structlog==24.1.0

# Visualization
networkx==3.2.1
matplotlib==3.8.2
```

2. **Configure the system:**
```bash
# Create configuration
cat > config.json << EOF
{
  "openai_api_key": "your-openai-key",
  "elasticsearch_url": "http://localhost:9200",
  "database_url": "postgresql://user:pass@localhost/security",
  "yara_rules_path": "./rules/",
  "deep_learning_model_path": "./models/threat_detection.h5",
  "api_host": "0.0.0.0",
  "api_port": 8001,
  "demo_mode": true
}
EOF
```

3. **Start required services:**
```bash
# Start Elasticsearch
docker run -d -p 9200:9200 -p 9300:9300 \
  -e "discovery.type=single-node" \
  -e "xpack.security.enabled=false" \
  elasticsearch:8.12.1

# Start PostgreSQL
docker run -d -p 5432:5432 \
  -e POSTGRES_USER=user \
  -e POSTGRES_PASSWORD=pass \
  -e POSTGRES_DB=security \
  postgres:16
```

4. **Run the Security Operations Center:**
```bash
# Start the SOC
python main_security_ops.py --demo

# In another terminal, open the dashboard
open dashboard/security_dashboard.html
```

5. **Test the system:**
```bash
# Submit a security event
curl -X POST http://localhost:8001/events \
  -H "Content-Type: application/json" \
  -d '{
    "type": "suspicious_login",
    "user": "admin",
    "source_ip": "192.168.1.100",
    "timestamp": "2024-01-20T10:30:00Z"
  }'

# Check incidents
curl http://localhost:8001/incidents

# Get compliance status
curl http://localhost:8001/compliance/SOC2

# Get executive report
curl http://localhost:8001/report/executive
```

## 🎯 Validation

Your AI Security Operations Center should now:
- ✅ Detect threats automatically using AI
- ✅ Investigate incidents without human intervention
- ✅ Respond to threats in real-time
- ✅ Hunt for threats proactively
- ✅ Ensure continuous compliance
- ✅ Generate executive reports
- ✅ Provide real-time dashboard
- ✅ Coordinate multiple security agents

## 🚀 Bonus Challenges

1. **Advanced Threat Detection:**
   - Implement deep learning models for APT detection
   - Add behavioral biometrics
   - Create custom YARA rules
   - Implement deception technology

2. **Automated Response:**
   - Integrate with EDR platforms
   - Automate patch management
   - Implement quarantine procedures
   - Create playbook automation

3. **Compliance Automation:**
   - Add more frameworks (NIST, CIS)
   - Implement evidence collection
   - Create audit trails
   - Generate compliance artifacts

4. **Integration:**
   - Connect to real SIEM platforms
   - Integrate with ticketing systems
   - Add Slack/Teams notifications
   - Implement SOAR platform integration

## 📚 Additional Resources

- [MITRE ATT&CK Framework](https://attack.mitre.org/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [AI for Cybersecurity](https://www.microsoft.com/security/blog/2023/11/08/ai-for-cybersecurity/)

## ⏭️ Next Exercise

Ready for the ultimate challenge? Move on to [Exercise 3: Intelligent Platform](../exercise3-intelligent-platform/) where you'll build a complete self-managing platform!