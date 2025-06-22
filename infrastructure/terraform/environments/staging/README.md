# Staging Environment Configuration

This directory contains Terraform configuration for the staging environment.

## Purpose

The staging environment is a production-like environment used for:
- Final testing before production deployment
- Performance testing and benchmarking
- User acceptance testing (UAT)
- Training and demonstrations

## Configuration Differences from Dev

### Scale
- **Compute**: Production-sized but with fewer instances
- **Storage**: Full replication enabled
- **Networking**: Complete security configurations
- **Monitoring**: Full observability stack

### Cost Optimization
- **Auto-scaling**: Enabled with conservative thresholds
- **Scheduled Scaling**: Scale down during off-hours
- **Reserved Instances**: 1-year commitments
- **Spot Instances**: For non-critical workloads

## Files

- `main.tf` - Main configuration file
- `variables.tf` - Variable definitions
- `terraform.tfvars` - Variable values (DO NOT COMMIT)
- `outputs.tf` - Output definitions
- `backend.tf` - State storage configuration

## Usage

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan

# Destroy resources (careful!)
terraform destroy
```

## State Management

State is stored in Azure Storage:
- Storage Account: `stmasteryaitfstate`
- Container: `tfstate`
- Key: `staging.terraform.tfstate`

## Key Differences from Development

1. **High Availability**
   - Multi-zone deployments
   - Load balancing enabled
   - Auto-failover configured

2. **Security Hardening**
   - WAF enabled
   - DDoS protection
   - Private endpoints
   - Encryption everywhere

3. **Monitoring**
   - Full APM suite
   - Custom dashboards
   - Alerting enabled
   - Log retention: 90 days

4. **Backup & DR**
   - Daily backups
   - Geo-replication
   - DR procedures tested

## Pre-Production Checklist

- [ ] All secrets in Key Vault
- [ ] Network policies reviewed
- [ ] Monitoring alerts configured
- [ ] Backup policies enabled
- [ ] Cost alerts set up
- [ ] Performance baselines established
- [ ] Security scan completed
- [ ] Documentation updated

## Promotion to Production

After successful staging validation:
1. Export tested configurations
2. Review and approve changes
3. Schedule production deployment
4. Execute runbook procedures
