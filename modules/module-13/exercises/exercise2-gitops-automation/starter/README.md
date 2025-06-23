# Exercise 2: GitOps Automation - Starter

This is the starter code for Exercise 2 of Module 13.

## 📁 Project Structure

```
starter/
├── environments/          # Environment-specific configurations
│   ├── dev/
│   ├── staging/
│   └── prod/
├── modules/              # Reusable Terraform modules
│   ├── network/
│   ├── webapp/
│   └── database/
├── .github/              # GitHub Actions workflows
│   └── workflows/
└── scripts/              # Helper scripts
```

## 🚀 Getting Started

1. Configure the Terraform backend by running the setup script
2. Create the basic modules following the instructions
3. Configure environments with their specific variables
4. Implement CI/CD workflows

## 📝 TODOs

- [ ] Create backend configuration script
- [ ] Implement network module
- [ ] Implement webapp module
- [ ] Implement database module
- [ ] Configure per-environment variables
- [ ] Create GitHub Actions workflows
- [ ] Add automated tests 