# Production Environment Configuration

This directory contains Terraform configuration for the production environment.

## 🚨 Critical Information

**THIS IS PRODUCTION** - All changes must go through:
1. Code review by 2+ team members
2. Approval from technical lead
3. Change Advisory Board (CAB) approval
4. Scheduled maintenance window

## Environment Characteristics

### High Availability
- **Multi-region**: Primary in East US, DR in West US
- **Zone Redundancy**: All services across 3+ zones
- **Auto-failover**: < 1 minute RTO
- **Load Balancing**: Global traffic management

### Security
- **Zero Trust Architecture**: Never trust, always verify
- **Private Endpoints**: No public exposure
- **WAF**: OWASP Top 10 protection
- **DDoS Protection**: Standard tier
- **Encryption**: At rest and in transit

### Compliance
- **SOC 2 Type II**: Annual audit
- **ISO 27001**: Certified
- **GDPR**: Compliant
- **HIPAA**: Ready (if needed)

## Infrastructure

### Compute
- **AKS**: 3+ node pools, 15+ nodes total
- **Functions**: Premium plan, always-on
- **App Services**: Isolated tier

### Storage
- **Redundancy**: GRS or GZRS
- **Backup**: Daily with 30-day retention
- **Disaster Recovery**: < 4 hour RPO

### Networking
- **ExpressRoute**: Dedicated connectivity
- **Private DNS**: Internal resolution
- **NSGs**: Least privilege access

## Deployment Process

### Pre-deployment
```bash
# 1. Pull latest code
git pull origin main

# 2. Review changes
terraform plan -detailed-exitcode

# 3. Generate change report
terraform show -json tfplan > change-report.json

# 4. Security scan
tfsec . --format json > security-report.json
```

### Deployment
```bash
# 1. Create backup of current state
terraform state pull > backup-$(date +%Y%m%d-%H%M%S).tfstate

# 2. Apply with approval
terraform apply tfplan

# 3. Verify deployment
./scripts/verify-production.sh
```

### Post-deployment
1. Monitor metrics for 30 minutes
2. Run smoke tests
3. Update runbooks
4. Notify stakeholders

## State Management

State is stored with enhanced security:
- Storage Account: `stmasteryaitfstateprod`
- Container: `tfstate-prod`
- Key: `prod.terraform.tfstate`
- Features:
  - Encryption with customer-managed keys
  - Blob versioning enabled
  - Soft delete (30 days)
  - Legal hold capable

## Monitoring & Alerts

### Critical Alerts (P1)
- Service down
- Security breach
- Data loss risk
- Performance < SLA

### Warning Alerts (P2)
- High resource usage (>80%)
- Unusual traffic patterns
- Failed backups
- Certificate expiration

## Cost Management

### Monthly Budget
- Alert at 80% threshold
- Auto-scale limits enforced
- Reserved instance optimization
- Spot instances for batch jobs

### Cost Attribution
- Tag enforcement policy
- Department chargebacks
- Monthly reports
- Optimization reviews

## Emergency Procedures

### Rollback Process
1. Stop deployment immediately
2. Assess impact
3. Execute rollback:
   ```bash
   terraform apply -target=module.affected_module -replace
   ```
4. Verify services restored
5. Post-mortem within 48 hours

### Incident Response
- **P1**: Page on-call immediately
- **P2**: Notify during business hours
- **Escalation**: Follow runbook procedures

## Access Control

### Required Permissions
- Read: All team members
- Plan: Senior developers
- Apply: DevOps engineers + approval
- Destroy: Forbidden (requires exception)

### Audit Requirements
- All actions logged
- Monthly access reviews
- Quarterly permission audits
- Annual security assessment

## Maintenance Windows

- **Standard**: Sundays 2-6 AM EST
- **Emergency**: Requires VP approval
- **Notification**: 72 hours advance (standard)
- **Communication**: Email + Slack + StatusPage

## Remember

> "Move fast and break things" does NOT apply to production.
> 
> Every change must be:
> - Tested in staging
> - Reviewed by peers
> - Approved by management
> - Carefully executed
> - Fully documented

**When in doubt, DON'T deploy.**
