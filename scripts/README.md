# 📜 Workshop Scripts

This directory contains essential scripts for the **Mastery AI Apps and Development Workshop**. These scripts help automate setup, validation, management, and organization tasks throughout your learning journey.

## 🚀 Available Scripts

### Core Setup Scripts

#### 1. **setup-workshop.sh** / **setup-workshop.ps1**
Complete workshop environment setup script.

**Features:**
- Installs all required tools (Python, Node.js, .NET, Docker, etc.)
- Configures development environment
- Sets up VS Code with extensions
- Creates Python virtual environment
- Configures Git and authenticates with GitHub/Azure

**Usage:**
```bash
# Linux/macOS
./scripts/setup-workshop.sh

# Windows PowerShell (Run as Administrator)
.\scripts\setup-workshop.ps1
```

#### 2. **validate-prerequisites.sh**
Comprehensive validation script that checks if your system meets all workshop requirements.

**Features:**
- Validates OS compatibility
- Checks hardware requirements (CPU, RAM, disk space)
- Verifies tool installations and versions
- Tests network connectivity
- Validates workshop structure
- Provides detailed pass/fail/warning report

**Usage:**
```bash
./scripts/validate-prerequisites.sh
```

#### 3. **quick-start.sh** / **quick-start.ps1**
Get started with the workshop in just 5 minutes!

**Features:**
- Quick requirements check
- Sets up first module with starter files
- Creates quick reference guide
- Configures VS Code workspace
- Interactive progress tracking
- Provides helpful tips

**Usage:**
```bash
# Linux/macOS
./scripts/quick-start.sh

# Windows PowerShell
.\scripts\quick-start.ps1
```

### Management Scripts

#### 4. **cleanup-resources.sh**
Safely clean up Azure resources created during the workshop.

**Features:**
- Module-specific cleanup
- Dry-run mode for safety
- Batch cleanup for all resources
- Resource group management
- Handles soft-deleted resources
- Progress tracking

**Usage:**
```bash
# Clean specific module resources
./scripts/cleanup-resources.sh --module 5

# Clean all workshop resources (dry run)
./scripts/cleanup-resources.sh --all --dry-run

# Clean specific resource group
./scripts/cleanup-resources.sh --resource-group my-workshop-rg

# Check deletion status
./scripts/cleanup-resources.sh --check
```

#### 5. **backup-progress.sh**
Backup your workshop progress and solutions.

**Features:**
- Selective module backup
- Option to include/exclude solutions
- Progress report generation
- Compression support
- Metadata tracking
- Custom backup naming

**Usage:**
```bash
# Backup all your work (excluding solutions)
./scripts/backup-progress.sh --modules all

# Backup modules 1-5 with solutions
./scripts/backup-progress.sh --modules 1-5 --solutions

# Backup specific modules
./scripts/backup-progress.sh --modules "1,3,5-7,10"

# Custom backup location and name
./scripts/backup-progress.sh --modules all --output ~/backups --name my-workshop-progress
```

### Organization Scripts

#### 6. **organize-modules.sh**
Creates standard directory structure for all modules.

**Features:**
- Creates organized folder structure
- Sets up exercise directories
- Creates documentation folders
- Adds navigation templates
- Generates exercise READMEs

**Usage:**
```bash
./scripts/organize-modules.sh
```

#### 7. **enhance-navigation.sh**
Adds comprehensive navigation to all workshop documents.

**Features:**
- Adds breadcrumb navigation
- Creates module navigation bars
- Adds quick navigation sidebars
- Generates workshop resource footers
- Links all related documents

**Usage:**
```bash
./scripts/enhance-navigation.sh
```

#### 8. **reorganize-files.sh**
Moves existing module files to the new organized structure.

**Features:**
- Reorganizes exercise files
- Moves documentation to proper folders
- Creates starter templates
- Maintains file relationships
- Generates index files

**Usage:**
```bash
./scripts/reorganize-files.sh
```

#### 9. **create-navigation-links.sh**
Creates comprehensive navigation links between all documents.

**Features:**
- Adds navigation to root documents
- Creates module navigation map
- Generates complete link index
- Verifies all internal links
- Reports broken links

**Usage:**
```bash
./scripts/create-navigation-links.sh
```

## 🔧 Script Requirements

### Operating Systems
- **Linux**: Ubuntu 20.04+, Debian 10+
- **macOS**: 12 Monterey or later
- **Windows**: Windows 11 with PowerShell 5.1+ (Run as Administrator)

### Shell Requirements
- **Bash**: Version 4.0+ (Linux/macOS)
- **PowerShell**: Version 5.1+ (Windows)
- **WSL2**: Recommended for Windows users

## 💡 Usage Tips

### Making Scripts Executable (Linux/macOS)
```bash
chmod +x scripts/*.sh
```

### Running Scripts from Any Directory
```bash
# From workshop root
./scripts/setup-workshop.sh

# From any subdirectory
../scripts/validate-prerequisites.sh
```

### Windows Execution Policy
If you encounter execution policy errors on Windows:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## 🎯 Script Workflow

### For Initial Setup
1. **setup-workshop.sh** - Install and configure everything
2. **validate-prerequisites.sh** - Verify setup was successful
3. **organize-modules.sh** - Create module structure
4. **quick-start.sh** - Get your first AI code running

### For Daily Use
1. **backup-progress.sh** - Save your work regularly
2. **cleanup-resources.sh** - Clean up after each module

### For Workshop Maintenance
1. **reorganize-files.sh** - Reorganize existing files
2. **enhance-navigation.sh** - Add navigation features
3. **create-navigation-links.sh** - Verify and fix links

## 🐛 Troubleshooting

### Common Issues

#### Permission Denied (Linux/macOS)
```bash
# Make script executable
chmod +x scripts/script-name.sh

# Run with proper permissions
sudo ./scripts/setup-workshop.sh  # Only if needed
```

#### PowerShell Script Blocked (Windows)
```powershell
# Unblock downloaded scripts
Get-ChildItem -Path scripts -Filter *.ps1 | Unblock-File

# Or run with bypass
powershell -ExecutionPolicy Bypass -File .\scripts\setup-workshop.ps1
```

#### Script Not Found
```bash
# Ensure you're in the workshop root directory
pwd  # Should show .../Mastery-AI-Apps-Dev

# Check script exists
ls scripts/
```

## 📊 Script Features Matrix

| Script | Auto-Install | Validation | Cleanup | Interactive | Dry-Run | Backup |
|--------|-------------|------------|---------|-------------|---------|---------|
| setup-workshop | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ |
| validate-prerequisites | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ |
| quick-start | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ |
| cleanup-resources | ❌ | ✅ | ✅ | ✅ | ✅ | ❌ |
| backup-progress | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ |
| organize-modules | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| enhance-navigation | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| reorganize-files | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| create-navigation-links | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ |

## 🔄 Updating Scripts

Scripts are maintained as part of the workshop. To get the latest versions:

```bash
git pull origin main
chmod +x scripts/*.sh  # Re-apply execute permissions
```

## 🤝 Contributing

If you find issues or have improvements for the scripts:
1. Open an issue describing the problem
2. Submit a pull request with your fix
3. Ensure scripts work on all supported platforms

## 📝 Script Conventions

All scripts follow these conventions:
- Clear error messages with color coding
- Progress indicators for long operations  
- Dry-run options where applicable
- Help text with -h or --help
- Non-destructive by default
- Cross-platform compatibility where possible

## 🆘 Getting Help

- Check script help: `./scripts/script-name.sh --help`
- Review workshop [TROUBLESHOOTING.md](../TROUBLESHOOTING.md)
- Search [GitHub Issues](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/issues)
- Ask in [GitHub Discussions](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/discussions)

---

Happy scripting! 🚀 These tools are here to make your workshop experience smooth and enjoyable.
