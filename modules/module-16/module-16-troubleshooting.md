# Module 16 - Security Implementation Troubleshooting Guide

## 🔧 Common Issues and Solutions

### Authentication Issues

#### Problem: "Could not validate credentials" (401 Error)
**Symptoms:**
- API returns 401 Unauthorized
- Token validation fails
- Microsoft Entra ID authentication not working

**Solutions:**
1. **Check token expiration:**
   ```python
   import jwt
   from datetime import datetime
   
   def debug_token(token: str):
       try:
           # Decode without verification for debugging
           payload = jwt.decode(token, options={"verify_signature": False})
           exp = payload.get('exp', 0)
           
           if exp < datetime.utcnow().timestamp():
               print("Token is expired!")
               print(f"Expired at: {datetime.fromtimestamp(exp)}")
           else:
               print(f"Token valid until: {datetime.fromtimestamp(exp)}")
               
           print(f"Token claims: {payload}")
           
       except Exception as e:
           print(f"Token decode error: {e}")
   ```

2. **Verify Microsoft Entra ID configuration:**
   ```bash
   # Check tenant configuration
   az account show
   
   # Verify app registration
   az ad app show --id $APP_ID
   
   # Check service principal
   az ad sp show --id $APP_ID
   ```

3. **Validate JWT secret in Key Vault:**
   ```python
   from azure.keyvault.secrets import SecretClient
   from azure.identity import DefaultAzureCredential
   
   credential = DefaultAzureCredential()
   client = SecretClient(
       vault_url="https://your-vault.vault.azure.net/",
       credential=credential
   )
   
   try:
       secret = client.get_secret("jwt-secret")
       print("Secret exists and is accessible")
   except Exception as e:
       print(f"Key Vault access error: {e}")
   ```

#### Problem: "Insufficient permissions" (403 Error)
**Symptoms:**
- User authenticated but cannot access resources
- Role-based access control failing

**Solutions:**
1. **Debug user roles:**
   ```python
   def debug_user_permissions(token: str):
       payload = jwt.decode(token, options={"verify_signature": False})
       
       print(f"User: {payload.get('sub')}")
       print(f"Roles: {payload.get('roles', [])}")
       print(f"Permissions: {payload.get('permissions', [])}")
       
       # Check role mapping
       for role in payload.get('roles', []):
           perms = ROLE_PERMISSIONS.get(role, [])
           print(f"Role '{role}' grants: {perms}")
   ```

2. **Verify RBAC configuration:**
   ```bash
   # Check user role assignments
   az role assignment list --assignee $USER_ID
   ```

### Encryption Issues

#### Problem: "Encryption failed" or "Decryption failed"
**Symptoms:**
- Data encryption/decryption operations fail
- Key Vault access errors
- Invalid ciphertext errors

**Solutions:**
1. **Test Key Vault connectivity:**
   ```python
   async def test_key_vault():
       from azure.keyvault.keys import KeyClient
       from azure.identity import DefaultAzureCredential
       
       try:
           credential = DefaultAzureCredential()
           client = KeyClient(
               vault_url="https://your-vault.vault.azure.net/",
               credential=credential
           )
           
           # List keys to test access
           keys = client.list_properties_of_keys()
           for key in keys:
               print(f"Key: {key.name}, Enabled: {key.enabled}")
               
       except Exception as e:
           print(f"Key Vault error: {e}")
           # Check Azure credentials
           print("Checking Azure credentials...")
           import os
           print(f"AZURE_TENANT_ID: {'Set' if os.getenv('AZURE_TENANT_ID') else 'Not set'}")
           print(f"AZURE_CLIENT_ID: {'Set' if os.getenv('AZURE_CLIENT_ID') else 'Not set'}")
           print(f"AZURE_CLIENT_SECRET: {'Set' if os.getenv('AZURE_CLIENT_SECRET') else 'Not set'}")
   ```

2. **Debug encryption envelope:**
   ```python
   def debug_encryption_envelope(envelope: dict):
       print("Encryption Envelope Debug:")
       print(f"Version: {envelope.get('version')}")
       print(f"KEK ID: {envelope.get('kek_id')}")
       print(f"Classification: {envelope.get('classification')}")
       print(f"Timestamp: {envelope.get('timestamp')}")
       
       # Check data integrity
       required_fields = ['version', 'kek_id', 'encrypted_dek', 'iv', 'tag']
       missing = [f for f in required_fields if f not in envelope]
       
       if missing:
           print(f"ERROR: Missing fields: {missing}")
       else:
           print("All required fields present")
   ```

3. **Verify encryption keys:**
   ```python
   # Test key operations
   from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
   
   def test_aes_encryption():
       try:
           key = os.urandom(32)  # 256-bit key
           iv = os.urandom(12)   # 96-bit IV for GCM
           
           cipher = Cipher(
               algorithms.AES(key),
               modes.GCM(iv),
               backend=default_backend()
           )
           
           # Test encrypt
           encryptor = cipher.encryptor()
           ciphertext = encryptor.update(b"test data") + encryptor.finalize()
           
           # Test decrypt
           cipher = Cipher(
               algorithms.AES(key),
               modes.GCM(iv, encryptor.tag),
               backend=default_backend()
           )
           decryptor = cipher.decryptor()
           plaintext = decryptor.update(ciphertext) + decryptor.finalize()
           
           print("Encryption test passed!")
           
       except Exception as e:
           print(f"Encryption test failed: {e}")
   ```

### Rate Limiting Issues

#### Problem: "Rate limit exceeded" (429 Error)
**Symptoms:**
- Requests being throttled
- Redis connection errors
- Inconsistent rate limiting

**Solutions:**
1. **Check Redis connectivity:**
   ```python
   import redis
   
   def test_redis_connection():
       try:
           r = redis.Redis(
               host='localhost',
               port=6379,
               decode_responses=True
           )
           
           # Test connection
           r.ping()
           print("Redis connection successful")
           
           # Check memory usage
           info = r.info('memory')
           print(f"Redis memory used: {info['used_memory_human']}")
           
           # List rate limit keys
           keys = r.keys('rate_limit:*')
           print(f"Active rate limits: {len(keys)}")
           
       except redis.ConnectionError as e:
           print(f"Redis connection failed: {e}")
           print("Check if Redis is running: sudo systemctl status redis")
   ```

2. **Debug rate limit state:**
   ```python
   def debug_rate_limit(user_id: str):
       r = redis.Redis(host='localhost', port=6379)
       key = f"rate_limit:{hashlib.md5(f'user:{user_id}'.encode()).hexdigest()}"
       
       # Get current state
       current_count = r.zcard(key)
       ttl = r.ttl(key)
       
       print(f"User: {user_id}")
       print(f"Current requests: {current_count}")
       print(f"Key TTL: {ttl} seconds")
       
       # Show request timestamps
       requests = r.zrange(key, 0, -1, withscores=True)
       for req, timestamp in requests:
           print(f"  Request at: {datetime.fromtimestamp(timestamp)}")
   ```

### Compliance Scanning Issues

#### Problem: Compliance scans failing or returning incorrect results
**Symptoms:**
- Compliance controls showing as non-compliant incorrectly
- Scan timeouts
- Missing evidence files

**Solutions:**
1. **Debug compliance control tests:**
   ```python
   async def debug_compliance_control(control_id: str):
       print(f"Testing control: {control_id}")
       
       # Map control to test function
       test_mapping = {
           "GDPR-1.1": test_encryption_at_rest,
           "HIPAA-1.1": test_access_controls,
           # ... other mappings
       }
       
       test_func = test_mapping.get(control_id)
       if not test_func:
           print(f"No test defined for {control_id}")
           return
       
       try:
           # Run test with detailed logging
           result = await test_func()
           print(f"Test result: {'PASSED' if result else 'FAILED'}")
           
       except Exception as e:
           print(f"Test error: {e}")
           import traceback
           traceback.print_exc()
   ```

2. **Verify Azure Monitor queries:**
   ```python
   from azure.monitor.query import LogsQueryClient
   
   async def test_monitor_queries():
       client = LogsQueryClient(credential=DefaultAzureCredential())
       
       # Test basic query
       query = "AzureDiagnostics | take 10"
       
       try:
           response = client.query_workspace(
               workspace_id="your-workspace-id",
               query=query,
               timespan=timedelta(hours=1)
           )
           
           if response.status == "Success":
               print(f"Query returned {len(response.tables[0].rows)} rows")
           else:
               print(f"Query failed: {response.status}")
               
       except Exception as e:
           print(f"Monitor query error: {e}")
   ```

### Security Monitoring Issues

#### Problem: Security incidents not being detected
**Symptoms:**
- Microsoft Sentinel not reporting incidents
- GitHub security alerts missing
- No automated remediation

**Solutions:**
1. **Verify Sentinel configuration:**
   ```python
   def check_sentinel_setup():
       from azure.mgmt.sentinel import SecurityInsights
       
       client = SecurityInsights(
           credential=DefaultAzureCredential(),
           subscription_id="your-subscription-id"
       )
       
       try:
           # List data connectors
           connectors = client.data_connectors.list(
               resource_group_name="your-rg",
               workspace_name="your-workspace"
           )
           
           for connector in connectors:
               print(f"Connector: {connector.name}")
               print(f"  Kind: {connector.kind}")
               print(f"  Status: {connector.properties.data_types}")
               
       except Exception as e:
           print(f"Sentinel error: {e}")
   ```

2. **Test GitHub security integration:**
   ```python
   def test_github_security():
       from github3 import GitHub
       
       gh = GitHub(token="your-token")
       
       try:
           # Check repository access
           repo = gh.repository("owner", "repo")
           
           # Check security features
           print(f"Security features enabled:")
           print(f"  Advanced Security: {repo.has_advanced_security}")
           print(f"  Secret scanning: {repo.secret_scanning_enabled}")
           print(f"  Vulnerability alerts: {repo.vulnerability_alerts_enabled}")
           
           # List recent alerts
           for alert in repo.code_scanning_alerts():
               print(f"Alert: {alert.rule.description}")
               
       except Exception as e:
           print(f"GitHub API error: {e}")
   ```

### Performance Issues

#### Problem: Slow API response times
**Symptoms:**
- High latency on security operations
- Timeouts during encryption
- Dashboard not updating

**Solutions:**
1. **Profile slow operations:**
   ```python
   import time
   import cProfile
   import pstats
   
   def profile_operation(func):
       """Profile function performance."""
       def wrapper(*args, **kwargs):
           profiler = cProfile.Profile()
           profiler.enable()
           
           start_time = time.time()
           result = func(*args, **kwargs)
           end_time = time.time()
           
           profiler.disable()
           
           print(f"\nOperation took: {end_time - start_time:.2f} seconds")
           
           # Print top 10 time consumers
           stats = pstats.Stats(profiler)
           stats.sort_stats('cumulative')
           stats.print_stats(10)
           
           return result
       return wrapper
   ```

2. **Optimize database queries:**
   ```python
   # Add indexes for common queries
   CREATE INDEX idx_incidents_timestamp ON security_incidents(timestamp DESC);
   CREATE INDEX idx_incidents_severity ON security_incidents(severity);
   CREATE INDEX idx_audit_logs_user ON audit_logs(user_id, timestamp);
   ```

## 🔍 Diagnostic Commands

### System Health Check
```bash
#!/bin/bash
# health_check.sh

echo "=== Security Platform Health Check ==="

# Check services
echo -e "\n[Services Status]"
systemctl status redis-server | grep Active
docker ps | grep security-platform

# Check Azure connectivity
echo -e "\n[Azure Connectivity]"
az account show --query name -o tsv

# Check Key Vault access
echo -e "\n[Key Vault Access]"
az keyvault secret list --vault-name $KEY_VAULT_NAME --query "[].name" -o tsv

# Check log files
echo -e "\n[Recent Errors]"
tail -n 20 /var/log/security-platform/error.log | grep ERROR

# Check disk space
echo -e "\n[Disk Space]"
df -h | grep -E "^/dev/"

# Check memory usage
echo -e "\n[Memory Usage]"
free -h

# Check network connectivity
echo -e "\n[Network Tests]"
nc -zv localhost 8000  # API
nc -zv localhost 6379  # Redis
```

### Security Audit Script
```python
# security_audit.py
import asyncio
from datetime import datetime, timedelta

async def run_security_audit():
    """Run comprehensive security audit."""
    
    print("🔒 Security Platform Audit")
    print("=" * 50)
    
    # Test authentication
    print("\n[Authentication Test]")
    token = await test_authentication()
    print(f"✓ Authentication working" if token else "✗ Authentication failed")
    
    # Test encryption
    print("\n[Encryption Test]")
    enc_result = await test_encryption_pipeline()
    print(f"✓ Encryption working" if enc_result else "✗ Encryption failed")
    
    # Test compliance
    print("\n[Compliance Test]")
    comp_result = await test_compliance_scanning()
    print(f"✓ Compliance scanning working" if comp_result else "✗ Compliance failed")
    
    # Test monitoring
    print("\n[Monitoring Test]")
    mon_result = await test_security_monitoring()
    print(f"✓ Security monitoring active" if mon_result else "✗ Monitoring failed")
    
    # Generate report
    print("\n[Audit Summary]")
    print(f"Audit completed at: {datetime.utcnow().isoformat()}")
    print(f"Overall status: {'PASS' if all([token, enc_result, comp_result, mon_result]) else 'FAIL'}")

asyncio.run(run_security_audit())
```

## 📞 Getting Help

### Resources
- **Microsoft Learn**: [Azure Security Documentation](https://learn.microsoft.com/azure/security/)
- **GitHub Support**: [GitHub Advanced Security](https://docs.github.com/en/get-started/learning-about-github/about-github-advanced-security)
- **Stack Overflow**: Tag questions with `azure-security`, `github-security`

### Community
- Join the workshop Slack channel: #module16-security
- GitHub Discussions: [Workshop Discussions](https://github.com/workshop/discussions)

### Escalation Path
1. Check this troubleshooting guide
2. Search existing GitHub issues
3. Ask in community channels
4. Create a new issue with:
   - Error messages
   - Steps to reproduce
   - Environment details
   - Diagnostic output

---

💡 **Pro Tip**: Always run the diagnostic scripts before asking for help. They provide valuable context that speeds up problem resolution!