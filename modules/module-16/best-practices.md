# Security Implementation Best Practices

## 🛡️ Zero Trust Architecture

### Core Principles

1. **Never Trust, Always Verify**
   ```python
   # Every request must be authenticated and authorized
   @app.middleware("http")
   async def verify_all_requests(request: Request, call_next):
       # Skip only health checks
       if request.url.path == "/health":
           return await call_next(request)
       
       # Verify authentication
       if not await verify_authentication(request):
           return JSONResponse(
               status_code=401,
               content={"error": "Authentication required"}
           )
       
       # Verify authorization
       if not await check_authorization(request):
           return JSONResponse(
               status_code=403,
               content={"error": "Insufficient permissions"}
           )
       
       return await call_next(request)
   ```

2. **Least Privilege Access**
   ```python
   # Define granular permissions
   ROLE_PERMISSIONS = {
       "viewer": ["read"],
       "operator": ["read", "execute"],
       "admin": ["read", "write", "execute", "delete"],
       "security_admin": ["read", "write", "execute", "delete", "audit", "configure"]
   }
   
   def enforce_least_privilege(user_role: str, required_permission: str) -> bool:
       """Enforce principle of least privilege."""
       permissions = ROLE_PERMISSIONS.get(user_role, [])
       return required_permission in permissions
   ```

3. **Assume Breach**
   ```python
   # Implement comprehensive monitoring
   class SecurityMonitor:
       def __init__(self):
           self.anomaly_threshold = 0.8
           self.baseline = self._establish_baseline()
       
       async def detect_anomalies(self, activity: Dict[str, Any]) -> bool:
           """Detect anomalous behavior assuming breach."""
           score = await self._calculate_anomaly_score(activity)
           
           if score > self.anomaly_threshold:
               await self._trigger_incident_response(activity)
               return True
           
           return False
   ```

### Implementation Checklist

- [ ] All endpoints require authentication
- [ ] Role-based access control implemented
- [ ] Session management with timeout
- [ ] Multi-factor authentication enabled
- [ ] Continuous verification of trust
- [ ] Network segmentation applied
- [ ] Encrypted communications enforced

## 🔐 Encryption Best Practices

### Data Classification

```python
from enum import Enum
from typing import Dict, Any

class DataSensitivity(Enum):
    PUBLIC = 1
    INTERNAL = 2
    CONFIDENTIAL = 3
    SECRET = 4
    TOP_SECRET = 5

def classify_data(data: Dict[str, Any]) -> DataSensitivity:
    """Classify data based on content analysis."""
    if contains_pii(data):
        return DataSensitivity.CONFIDENTIAL
    elif contains_financial_data(data):
        return DataSensitivity.SECRET
    elif contains_health_info(data):
        return DataSensitivity.TOP_SECRET
    elif contains_internal_info(data):
        return DataSensitivity.INTERNAL
    else:
        return DataSensitivity.PUBLIC
```

### Encryption Standards

1. **Encryption at Rest**
   ```python
   # Use AES-256-GCM for data at rest
   from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
   
   def encrypt_at_rest(data: bytes, key: bytes) -> tuple[bytes, bytes, bytes]:
       """Encrypt data using AES-256-GCM."""
       iv = os.urandom(12)  # 96-bit IV for GCM
       cipher = Cipher(
           algorithms.AES(key),
           modes.GCM(iv),
           backend=default_backend()
       )
       encryptor = cipher.encryptor()
       ciphertext = encryptor.update(data) + encryptor.finalize()
       return ciphertext, iv, encryptor.tag
   ```

2. **Encryption in Transit**
   ```python
   # Enforce TLS 1.3
   ssl_context = ssl.create_default_context()
   ssl_context.minimum_version = ssl.TLSVersion.TLSv1_3
   ssl_context.check_hostname = True
   ssl_context.verify_mode = ssl.CERT_REQUIRED
   ```

3. **Key Management**
   ```python
   class KeyManager:
       """Centralized key management with rotation."""
       
       def __init__(self, key_vault_url: str):
           self.key_vault = KeyVaultClient(key_vault_url)
           self.rotation_period = timedelta(days=90)
       
       async def get_or_create_key(self, key_name: str) -> Key:
           """Get key with automatic rotation check."""
           key = await self.key_vault.get_key(key_name)
           
           if self._needs_rotation(key):
               new_key = await self._rotate_key(key_name)
               await self._reencrypt_data(key, new_key)
               return new_key
           
           return key
   ```

### Encryption Decision Matrix

| Data Type | Encryption Method | Key Type | Rotation Period |
|-----------|------------------|----------|-----------------|
| PII | AES-256-GCM | DEK + KEK | 90 days |
| PHI | AES-256-GCM + HSM | HSM-backed | 60 days |
| Financial | RSA-4096 + AES-256 | Certificate | 365 days |
| Secrets | Envelope Encryption | Master Key | 30 days |

## 📊 Compliance Implementation

### GDPR Compliance

```python
class GDPRCompliance:
    """GDPR compliance implementation."""
    
    def __init__(self):
        self.consent_store = ConsentStore()
        self.audit_logger = AuditLogger()
    
    async def process_personal_data(
        self,
        user_id: str,
        data: Dict[str, Any],
        purpose: str
    ) -> ProcessingResult:
        """Process personal data with GDPR compliance."""
        # 1. Verify consent
        if not await self.consent_store.has_consent(user_id, purpose):
            raise ConsentRequiredError(f"No consent for {purpose}")
        
        # 2. Minimize data collection
        minimized_data = self._minimize_data(data, purpose)
        
        # 3. Process with audit trail
        result = await self._process_data(minimized_data)
        
        # 4. Log for compliance
        await self.audit_logger.log_processing(
            user_id=user_id,
            purpose=purpose,
            data_categories=self._get_data_categories(minimized_data),
            timestamp=datetime.utcnow()
        )
        
        return result
    
    async def handle_data_request(
        self,
        user_id: str,
        request_type: str
    ) -> DataRequestResult:
        """Handle GDPR data subject requests."""
        if request_type == "access":
            return await self._provide_data_export(user_id)
        elif request_type == "erasure":
            return await self._delete_user_data(user_id)
        elif request_type == "portability":
            return await self._export_portable_data(user_id)
        elif request_type == "rectification":
            return await self._allow_data_correction(user_id)
```

### HIPAA Compliance

```python
class HIPAACompliance:
    """HIPAA compliance for healthcare data."""
    
    def __init__(self):
        self.access_control = AccessControlManager()
        self.audit_system = HIPAAAuditSystem()
    
    async def access_phi(
        self,
        user: User,
        patient_id: str,
        purpose: str
    ) -> PHIAccessResult:
        """Access PHI with HIPAA safeguards."""
        # 1. Verify minimum necessary
        if not self._is_minimum_necessary(user, purpose):
            raise HIPAAViolationError("Access exceeds minimum necessary")
        
        # 2. Check authorization
        if not await self.access_control.is_authorized(user, patient_id):
            raise UnauthorizedAccessError()
        
        # 3. Retrieve with encryption
        encrypted_phi = await self._retrieve_encrypted_phi(patient_id)
        
        # 4. Audit access
        await self.audit_system.log_phi_access(
            user_id=user.id,
            patient_id=patient_id,
            purpose=purpose,
            accessed_fields=self._get_accessed_fields(purpose),
            timestamp=datetime.utcnow()
        )
        
        # 5. Decrypt only necessary fields
        return self._decrypt_minimum_fields(encrypted_phi, purpose)
```

### SOC2 Compliance

```python
class SOC2Controls:
    """SOC2 trust service criteria implementation."""
    
    async def implement_security_controls(self):
        """Implement SOC2 security controls."""
        controls = {
            "CC6.1": self._logical_access_controls(),
            "CC6.2": self._new_user_access(),
            "CC6.3": self._modify_access(),
            "CC6.4": self._remove_access(),
            "CC6.5": self._privileged_access(),
            "CC6.6": self._physical_access(),
            "CC6.7": self._authentication(),
            "CC6.8": self._intrusion_detection()
        }
        
        for control_id, implementation in controls.items():
            await self._validate_control(control_id, implementation)
    
    async def _logical_access_controls(self):
        """CC6.1: Logical access security software."""
        return {
            "firewall": await self._verify_firewall_config(),
            "ids": await self._verify_intrusion_detection(),
            "access_control": await self._verify_access_lists(),
            "encryption": await self._verify_encryption_enabled()
        }
```

## 🚨 Incident Response

### Incident Response Plan

```python
class IncidentResponsePlan:
    """Automated incident response implementation."""
    
    def __init__(self):
        self.phases = {
            "preparation": self._prepare,
            "identification": self._identify,
            "containment": self._contain,
            "eradication": self._eradicate,
            "recovery": self._recover,
            "lessons_learned": self._post_incident
        }
    
    async def respond_to_incident(self, incident: SecurityIncident):
        """Execute incident response plan."""
        for phase_name, phase_handler in self.phases.items():
            logger.info(f"Executing phase: {phase_name}")
            
            try:
                result = await phase_handler(incident)
                incident.add_phase_result(phase_name, result)
                
                if result.requires_escalation:
                    await self._escalate_incident(incident, phase_name)
                
            except Exception as e:
                logger.error(f"Phase {phase_name} failed: {e}")
                await self._handle_phase_failure(incident, phase_name, e)
```

### Automated Remediation

```python
class AutomatedRemediation:
    """Automated security remediation patterns."""
    
    def __init__(self):
        self.remediation_strategies = {
            ThreatType.MALWARE: self._remediate_malware,
            ThreatType.UNAUTHORIZED_ACCESS: self._remediate_unauthorized_access,
            ThreatType.DATA_EXFILTRATION: self._remediate_data_exfiltration,
            ThreatType.DDOS: self._remediate_ddos,
            ThreatType.CREDENTIAL_COMPROMISE: self._remediate_credential_compromise
        }
    
    async def remediate(self, threat: Threat) -> RemediationResult:
        """Execute automated remediation."""
        strategy = self.remediation_strategies.get(threat.type)
        
        if not strategy:
            return RemediationResult(
                success=False,
                reason="No automated remediation available"
            )
        
        # Execute with circuit breaker
        return await self._execute_with_circuit_breaker(
            strategy,
            threat,
            max_retries=3,
            timeout=300
        )
```

## 🔍 Security Monitoring

### Continuous Monitoring

```python
class SecurityMonitoringPipeline:
    """Real-time security monitoring pipeline."""
    
    def __init__(self):
        self.monitors = [
            NetworkMonitor(),
            ApplicationMonitor(),
            DatabaseMonitor(),
            UserBehaviorMonitor(),
            FileIntegrityMonitor()
        ]
        
        self.alert_thresholds = {
            "critical": 0.95,
            "high": 0.80,
            "medium": 0.60,
            "low": 0.40
        }
    
    async def start_monitoring(self):
        """Start all security monitors."""
        tasks = []
        
        for monitor in self.monitors:
            task = asyncio.create_task(
                self._monitor_with_alerting(monitor)
            )
            tasks.append(task)
        
        # Aggregate results
        await self._aggregate_monitoring_data(tasks)
    
    async def _monitor_with_alerting(self, monitor: SecurityMonitor):
        """Monitor with automatic alerting."""
        async for event in monitor.stream_events():
            risk_score = await self._calculate_risk_score(event)
            
            for severity, threshold in self.alert_thresholds.items():
                if risk_score >= threshold:
                    await self._create_alert(event, severity, risk_score)
                    break
```

### Security Metrics

```python
class SecurityMetrics:
    """Key security metrics tracking."""
    
    def __init__(self):
        self.metrics = {
            "mean_time_to_detect": TimeSeries(),
            "mean_time_to_respond": TimeSeries(),
            "false_positive_rate": RateMetric(),
            "patch_compliance_rate": PercentageMetric(),
            "security_training_completion": PercentageMetric(),
            "vulnerability_density": RatioMetric(),
            "incident_closure_rate": RateMetric()
        }
    
    async def calculate_security_posture(self) -> SecurityPosture:
        """Calculate overall security posture score."""
        scores = {}
        
        for metric_name, metric in self.metrics.items():
            scores[metric_name] = await metric.calculate_score()
        
        # Weighted average
        weights = {
            "mean_time_to_detect": 0.20,
            "mean_time_to_respond": 0.20,
            "false_positive_rate": 0.15,
            "patch_compliance_rate": 0.15,
            "security_training_completion": 0.10,
            "vulnerability_density": 0.10,
            "incident_closure_rate": 0.10
        }
        
        overall_score = sum(
            scores[metric] * weight 
            for metric, weight in weights.items()
        )
        
        return SecurityPosture(
            score=overall_score,
            metrics=scores,
            recommendations=self._generate_recommendations(scores)
        )
```

## 🛠️ Security Development Lifecycle

### Secure Coding Practices

```python
# Input validation
def validate_input(data: str, input_type: InputType) -> str:
    """Validate and sanitize all input."""
    validators = {
        InputType.EMAIL: validate_email,
        InputType.URL: validate_url,
        InputType.PHONE: validate_phone,
        InputType.SQL: validate_and_escape_sql,
        InputType.HTML: sanitize_html,
        InputType.JSON: validate_json_schema
    }
    
    validator = validators.get(input_type)
    if not validator:
        raise ValueError(f"Unknown input type: {input_type}")
    
    return validator(data)

# Output encoding
def encode_output(data: str, context: OutputContext) -> str:
    """Encode output based on context."""
    encoders = {
        OutputContext.HTML: html.escape,
        OutputContext.URL: urllib.parse.quote,
        OutputContext.JSON: json.dumps,
        OutputContext.SQL: sql_escape,
        OutputContext.LDAP: ldap_escape
    }
    
    encoder = encoders.get(context)
    if not encoder:
        raise ValueError(f"Unknown output context: {context}")
    
    return encoder(data)
```

### Security Testing

```python
class SecurityTestSuite:
    """Automated security testing."""
    
    async def run_security_tests(self):
        """Run comprehensive security test suite."""
        test_results = {}
        
        # Static analysis
        test_results["sast"] = await self._run_static_analysis()
        
        # Dynamic analysis
        test_results["dast"] = await self._run_dynamic_analysis()
        
        # Dependency scanning
        test_results["dependencies"] = await self._scan_dependencies()
        
        # Container scanning
        test_results["containers"] = await self._scan_containers()
        
        # Infrastructure scanning
        test_results["infrastructure"] = await self._scan_infrastructure()
        
        # Penetration testing
        test_results["pentest"] = await self._run_penetration_tests()
        
        return SecurityTestReport(
            results=test_results,
            vulnerabilities=self._aggregate_vulnerabilities(test_results),
            risk_score=self._calculate_risk_score(test_results)
        )
```

## 📋 Security Checklist

### Pre-Deployment

- [ ] All code reviewed for security vulnerabilities
- [ ] Dependencies scanned and updated
- [ ] Security tests passed
- [ ] Encryption properly implemented
- [ ] Authentication/authorization verified
- [ ] Logging and monitoring configured
- [ ] Incident response plan tested
- [ ] Compliance controls validated

### Production

- [ ] Security monitoring active
- [ ] Automated patching enabled
- [ ] Backup and recovery tested
- [ ] Access reviews scheduled
- [ ] Compliance audits planned
- [ ] Security training completed
- [ ] Threat modeling updated
- [ ] Disaster recovery verified

## 🎯 Key Takeaways

1. **Defense in Depth**: Layer security controls
2. **Fail Secure**: Default to secure state on failure
3. **Least Privilege**: Minimal necessary access
4. **Separation of Duties**: No single point of compromise
5. **Security by Design**: Build security in, not bolt on
6. **Continuous Improvement**: Security is a journey

---

Remember: Security is everyone's responsibility. These practices should be embedded in your development culture, not just implemented as checkboxes.