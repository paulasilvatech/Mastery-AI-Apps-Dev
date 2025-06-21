#!/bin/bash

# ========================================================================
# Mastery AI Apps and Development Workshop - Progress Backup Script
# ========================================================================
# This script helps backup your workshop progress and solutions
# ========================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Default values
BACKUP_DIR="workshop-backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="mastery-ai-workshop-backup-$TIMESTAMP"
INCLUDE_SOLUTIONS=false
MODULES_TO_BACKUP=""
COMPRESS=true

# Functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${PURPLE}ℹ $1${NC}"
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Backup your Mastery AI Apps and Development Workshop progress.

OPTIONS:
    -m, --modules RANGE    Modules to backup (e.g., "1-5" or "all")
    -o, --output DIR       Output directory (default: workshop-backups)
    -n, --name NAME        Backup name (default: auto-generated with timestamp)
    -s, --solutions        Include solution folders in backup
    -nc, --no-compress     Don't compress the backup
    -h, --help            Show this help message

EXAMPLES:
    # Backup all your work (excluding solutions)
    $0 --modules all

    # Backup modules 1-5 with solutions
    $0 --modules 1-5 --solutions

    # Backup specific modules
    $0 --modules "1,3,5-7,10"

    # Custom backup location and name
    $0 --modules all --output ~/backups --name my-workshop-progress

EOF
    exit 1
}

parse_module_range() {
    local range=$1
    local modules=()
    
    if [[ "$range" == "all" ]]; then
        for i in {1..30}; do
            modules+=($i)
        done
    else
        # Parse comma-separated ranges like "1,3,5-7,10"
        IFS=',' read -ra PARTS <<< "$range"
        for part in "${PARTS[@]}"; do
            if [[ "$part" =~ ^([0-9]+)-([0-9]+)$ ]]; then
                # Range like "5-7"
                start=${BASH_REMATCH[1]}
                end=${BASH_REMATCH[2]}
                for i in $(seq $start $end); do
                    modules+=($i)
                done
            elif [[ "$part" =~ ^[0-9]+$ ]]; then
                # Single number
                modules+=($part)
            else
                print_error "Invalid module specification: $part"
                exit 1
            fi
        done
    fi
    
    # Remove duplicates and sort
    modules=($(printf "%s\n" "${modules[@]}" | sort -nu))
    echo "${modules[@]}"
}

check_module_progress() {
    local module_num=$1
    local module_dir="modules/module-$(printf "%02d" $module_num)"
    local progress_indicators=(
        "*.py"
        "*.js"
        "*.ts"
        "*.cs"
        "*.md"
        ".vscode/"
        "package.json"
        "requirements.txt"
        ".env"
    )
    
    if [[ ! -d "$module_dir" ]]; then
        return 1
    fi
    
    # Check if any work has been done in the module
    for indicator in "${progress_indicators[@]}"; do
        if find "$module_dir" -name "$indicator" -not -path "*/solution/*" 2>/dev/null | grep -q .; then
            return 0
        fi
    done
    
    return 1
}

create_backup_structure() {
    local backup_path=$1
    
    mkdir -p "$backup_path"
    mkdir -p "$backup_path/modules"
    mkdir -p "$backup_path/notes"
    mkdir -p "$backup_path/custom-scripts"
    
    # Create backup metadata
    cat > "$backup_path/backup-info.json" << EOF
{
    "workshop": "Mastery AI Apps and Development",
    "backup_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "backup_timestamp": "$TIMESTAMP",
    "machine": "$(hostname)",
    "user": "$(whoami)",
    "modules_backed_up": [$(IFS=,; echo "${MODULES_TO_BACKUP[*]}")],
    "include_solutions": $([[ "$INCLUDE_SOLUTIONS" == "true" ]] && echo "true" || echo "false"),
    "git_commit": "$(git rev-parse HEAD 2>/dev/null || echo "unknown")"
}
EOF
}

backup_module() {
    local module_num=$1
    local backup_path=$2
    local module_dir="modules/module-$(printf "%02d" $module_num)"
    local target_dir="$backup_path/modules/module-$(printf "%02d" $module_num)"
    
    if [[ ! -d "$module_dir" ]]; then
        print_warning "Module $module_num directory not found, skipping"
        return
    fi
    
    print_info "Backing up Module $module_num..."
    
    # Create module backup directory
    mkdir -p "$target_dir"
    
    # Define what to copy
    local copy_patterns=(
        "*.py"
        "*.js"
        "*.ts"
        "*.cs"
        "*.java"
        "*.go"
        "*.rb"
        "*.md"
        "*.txt"
        "*.json"
        "*.yaml"
        "*.yml"
        "*.toml"
        "*.ini"
        "*.env*"
        "*.gitignore"
        "Dockerfile*"
        "docker-compose*"
        "Makefile"
        ".vscode"
        "exercises"
        "src"
        "tests"
        "docs"
    )
    
    # Copy files matching patterns
    for pattern in "${copy_patterns[@]}"; do
        if [[ "$INCLUDE_SOLUTIONS" == "false" ]]; then
            # Exclude solution directories
            find "$module_dir" -name "$pattern" -not -path "*/solution/*" -exec cp -r --parents {} "$target_dir/" \; 2>/dev/null || true
        else
            # Include everything
            find "$module_dir" -name "$pattern" -exec cp -r --parents {} "$target_dir/" \; 2>/dev/null || true
        fi
    done
    
    # Fix paths (remove the module_dir prefix)
    if [[ -d "$target_dir/$module_dir" ]]; then
        mv "$target_dir/$module_dir"/* "$target_dir/" 2>/dev/null || true
        rm -rf "$target_dir/modules"
    fi
    
    print_success "Module $module_num backed up"
}

backup_workspace_files() {
    local backup_path=$1
    
    print_info "Backing up workspace files..."
    
    # Backup root-level workspace files if they exist
    local workspace_files=(
        ".vscode/settings.json"
        ".vscode/extensions.json"
        ".vscode/tasks.json"
        ".vscode/launch.json"
        "requirements.txt"
        "package.json"
        "package-lock.json"
        ".env"
        ".env.local"
        "docker-compose.yml"
        "NOTES.md"
        "TODO.md"
    )
    
    for file in "${workspace_files[@]}"; do
        if [[ -f "$file" ]]; then
            cp --parents "$file" "$backup_path/" 2>/dev/null || true
            print_success "Backed up: $file"
        fi
    done
    
    # Backup any custom scripts
    if [[ -d "my-scripts" ]] || [[ -d "custom-scripts" ]]; then
        cp -r my-scripts "$backup_path/custom-scripts/" 2>/dev/null || true
        cp -r custom-scripts "$backup_path/custom-scripts/" 2>/dev/null || true
        print_success "Backed up custom scripts"
    fi
}

create_progress_report() {
    local backup_path=$1
    local report_file="$backup_path/PROGRESS_REPORT.md"
    
    print_info "Generating progress report..."
    
    cat > "$report_file" << EOF
# Workshop Progress Report

Generated: $(date)

## Summary

- **Total Modules Attempted**: ${#MODULES_TO_BACKUP[@]}
- **Backup Include Solutions**: $([[ "$INCLUDE_SOLUTIONS" == "true" ]] && echo "Yes" || echo "No")

## Module Progress

EOF
    
    for module in "${MODULES_TO_BACKUP[@]}"; do
        local module_dir="modules/module-$(printf "%02d" $module)"
        local status="Not Started"
        
        if check_module_progress "$module"; then
            status="In Progress"
            
            # Check if exercises are completed
            if [[ -d "$module_dir/exercises/exercise3/solution" ]] && \
               find "$module_dir/exercises/exercise3" -name "*.py" -o -name "*.js" -o -name "*.ts" 2>/dev/null | grep -q .; then
                status="Likely Complete"
            fi
        fi
        
        echo "- **Module $module**: $status" >> "$report_file"
    done
    
    echo -e "\n## Notes\n" >> "$report_file"
    echo "This backup contains your workshop progress. To restore:" >> "$report_file"
    echo "1. Extract the backup to a new directory" >> "$report_file"
    echo "2. Copy the module folders back to your workshop directory" >> "$report_file"
    echo "3. Review the backup-info.json for details about this backup" >> "$report_file"
    
    print_success "Progress report generated"
}

compress_backup() {
    local backup_path=$1
    local archive_name="${backup_path}.tar.gz"
    
    print_info "Compressing backup..."
    
    tar -czf "$archive_name" -C "$(dirname "$backup_path")" "$(basename "$backup_path")"
    
    # Remove uncompressed directory
    rm -rf "$backup_path"
    
    # Get file size
    local size=$(ls -lh "$archive_name" | awk '{print $5}')
    
    print_success "Backup compressed: $archive_name ($size)"
    
    return 0
}

main() {
    clear
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║   Mastery AI Apps and Development Workshop                  ║"
    echo "║              Progress Backup Tool                            ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Check if in workshop directory
    if [[ ! -d "modules" ]] || [[ ! -f "README.md" ]]; then
        print_error "Not in workshop root directory"
        print_info "Please run this script from the workshop root directory"
        exit 1
    fi
    
    # Parse modules to backup
    if [[ -z "$MODULES_TO_BACKUP" ]]; then
        print_error "No modules specified"
        print_info "Use --modules to specify which modules to backup"
        exit 1
    fi
    
    MODULES_TO_BACKUP=($(parse_module_range "$MODULES_TO_BACKUP"))
    
    print_header "Backup Configuration"
    echo "Modules to backup: ${MODULES_TO_BACKUP[*]}"
    echo "Include solutions: $INCLUDE_SOLUTIONS"
    echo "Output directory: $BACKUP_DIR"
    echo "Backup name: $BACKUP_NAME"
    echo "Compress: $COMPRESS"
    
    # Create backup directory
    local full_backup_path="$BACKUP_DIR/$BACKUP_NAME"
    create_backup_structure "$full_backup_path"
    
    # Backup each module
    print_header "Backing Up Modules"
    for module in "${MODULES_TO_BACKUP[@]}"; do
        backup_module "$module" "$full_backup_path"
    done
    
    # Backup workspace files
    backup_workspace_files "$full_backup_path"
    
    # Generate progress report
    create_progress_report "$full_backup_path"
    
    # Compress if requested
    if [[ "$COMPRESS" == "true" ]]; then
        compress_backup "$full_backup_path"
        local final_path="${full_backup_path}.tar.gz"
    else
        local final_path="$full_backup_path"
    fi
    
    # Summary
    print_header "Backup Complete!"
    print_success "Your workshop progress has been backed up to:"
    echo -e "${GREEN}$final_path${NC}"
    echo
    print_info "To restore this backup later:"
    if [[ "$COMPRESS" == "true" ]]; then
        echo "1. Extract: tar -xzf $final_path"
    else
        echo "1. Copy the backup folder to your desired location"
    fi
    echo "2. Review PROGRESS_REPORT.md for your progress summary"
    echo "3. Copy module folders back to continue where you left off"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--modules)
            MODULES_TO_BACKUP="$2"
            shift 2
            ;;
        -o|--output)
            BACKUP_DIR="$2"
            shift 2
            ;;
        -n|--name)
            BACKUP_NAME="$2"
            shift 2
            ;;
        -s|--solutions)
            INCLUDE_SOLUTIONS=true
            shift
            ;;
        -nc|--no-compress)
            COMPRESS=false
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Run main function
main
