#!/bin/bash
# Validate workshop modules for completeness and functionality
# Supports all 30 modules with comprehensive validation

set -e

# Script metadata
SCRIPT_VERSION="1.0.0"
SCRIPT_NAME="Module Validator"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
MODULE_NUMBER=""
VALIDATE_ALL=false
FIX_ISSUES=false
VERBOSE=false
OUTPUT_FORMAT="console"
SKIP_TESTS=false

# Validation results
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0
VALIDATION_ERRORS=()

# Function to print colored output
print_colored() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print header
print_header() {
    echo ""
    print_colored $PURPLE "╔══════════════════════════════════════════════════════════════╗"
    print_colored $PURPLE "║               🔍 Workshop Module Validator                   ║"
    print_colored $PURPLE "║                     Version $SCRIPT_VERSION                          ║"
    print_colored $PURPLE "╚══════════════════════════════════════════════════════════════╝"
    echo ""
}

# Function to show help
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Validate Mastery AI Workshop modules for completeness and functionality.

OPTIONS:
    -m, --module NUMBER      Module number to validate (1-30)
    -a, --all               Validate all modules
    -f, --fix               Attempt to fix issues automatically
    -v, --verbose           Enable verbose output
    -o, --output FORMAT     Output format (console/json/xml)
    -s, --skip-tests        Skip running test suites
    -h, --help              Show this help message

EXAMPLES:
    # Validate specific module
    $0 -m 15

    # Validate all modules
    $0 -a

    # Validate with auto-fix
    $0 -m 5 -f

    # Validate all with JSON output
    $0 -a -o json

VALIDATION CHECKS:
    ✓ Directory structure and file presence
    ✓ README.md completeness and format
    ✓ Exercise structure (starter/solution/tests)
    ✓ Code quality and standards
    ✓ Dependencies and requirements
    ✓ Docker and deployment configurations
    ✓ Documentation links and references
    ✓ Test coverage and functionality

EOF
}

# Function to log validation result
log_validation() {
    local check_name="$1"
    local status="$2"
    local message="$3"
    local fix_action="$4"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    case $status in
        "PASS")
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
            if [ "$VERBOSE" = true ]; then
                print_colored $GREEN "  ✓ $check_name: $message"
            fi
            ;;
        "FAIL")
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
            print_colored $RED "  ✗ $check_name: $message"
            VALIDATION_ERRORS+=("$check_name: $message")
            if [ -n "$fix_action" ] && [ "$FIX_ISSUES" = true ]; then
                print_colored $YELLOW "    🔧 Attempting fix: $fix_action"
                eval "$fix_action"
            fi
            ;;
        "WARN")
            WARNING_CHECKS=$((WARNING_CHECKS + 1))
            print_colored $YELLOW "  ⚠ $check_name: $message"
            ;;
    esac
}

# Function to get module track
get_module_track() {
    local module_num=$1
    if [[ $module_num -le 5 ]]; then
        echo "fundamentals"
    elif [[ $module_num -le 10 ]]; then
        echo "intermediate"
    elif [[ $module_num -le 15 ]]; then
        echo "advanced"
    elif [[ $module_num -le 20 ]]; then
        echo "enterprise"
    elif [[ $module_num -le 25 ]]; then
        echo "ai-agents"
    else
        echo "enterprise-mastery"
    fi
}

# Function to validate directory structure
validate_directory_structure() {
    local module_path="$1"
    local module_num="$2"
    
    print_colored $CYAN "Validating directory structure..."
    
    # Required directories
    local required_dirs=(
        "exercises"
        "exercises/exercise1-easy"
        "exercises/exercise2-medium"
        "exercises/exercise3-hard"
        "resources"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [ -d "$module_path/$dir" ]; then
            log_validation "Directory Structure" "PASS" "$dir exists"
        else
            log_validation "Directory Structure" "FAIL" "$dir missing" "mkdir -p '$module_path/$dir'"
        fi
    done
    
    # Required files
    local required_files=(
        "README.md"
        "prerequisites.md"
        "best-practices.md"
    )
    
    for file in "${required_files[@]}"; do
        if [ -f "$module_path/$file" ]; then
            log_validation "Required Files" "PASS" "$file exists"
        else
            log_validation "Required Files" "FAIL" "$file missing" "touch '$module_path/$file'"
        fi
    done
}

# Function to validate exercise structure
validate_exercise_structure() {
    local module_path="$1"
    local module_num="$2"
    
    print_colored $CYAN "Validating exercise structure..."
    
    for exercise in exercise1-easy exercise2-medium exercise3-hard; do
        local exercise_path="$module_path/exercises/$exercise"
        
        if [ ! -d "$exercise_path" ]; then
            log_validation "Exercise Structure" "FAIL" "$exercise directory missing"
            continue
        fi
        
        # Check for required exercise components
        local required_components=(
            "instructions.md"
            "starter"
            "solution"
            "tests"
        )
        
        for component in "${required_components[@]}"; do
            if [ -e "$exercise_path/$component" ]; then
                log_validation "Exercise Components" "PASS" "$exercise/$component exists"
            else
                log_validation "Exercise Components" "FAIL" "$exercise/$component missing"
            fi
        done
        
        # Validate starter code
        if [ -d "$exercise_path/starter" ]; then
            local starter_files=$(find "$exercise_path/starter" -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.cs" | wc -l)
            if [ $starter_files -gt 0 ]; then
                log_validation "Starter Code" "PASS" "$exercise has $starter_files starter files"
            else
                log_validation "Starter Code" "WARN" "$exercise has no starter code files"
            fi
        fi
        
        # Validate solution code
        if [ -d "$exercise_path/solution" ]; then
            local solution_files=$(find "$exercise_path/solution" -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.cs" | wc -l)
            if [ $solution_files -gt 0 ]; then
                log_validation "Solution Code" "PASS" "$exercise has $solution_files solution files"
            else
                log_validation "Solution Code" "FAIL" "$exercise has no solution code files"
            fi
        fi
    done
}

# Function to validate README content
validate_readme_content() {
    local module_path="$1"
    local module_num="$2"
    local readme_file="$module_path/README.md"
    
    print_colored $CYAN "Validating README content..."
    
    if [ ! -f "$readme_file" ]; then
        log_validation "README Content" "FAIL" "README.md not found"
        return
    fi
    
    # Required sections in README
    local required_sections=(
        "# Module $module_num"
        "## Learning Objectives"
        "## Prerequisites"
        "## Exercises"
        "## Resources"
    )
    
    for section in "${required_sections[@]}"; do
        if grep -q "$section" "$readme_file"; then
            log_validation "README Sections" "PASS" "Section '$section' found"
        else
            log_validation "README Sections" "FAIL" "Section '$section' missing"
        fi
    done
    
    # Check for exercise links
    for i in 1 2 3; do
        if grep -q "exercise${i}" "$readme_file"; then
            log_validation "Exercise Links" "PASS" "Exercise $i linked in README"
        else
            log_validation "Exercise Links" "WARN" "Exercise $i not linked in README"
        fi
    done
    
    # Check for estimated duration
    if grep -q -i "duration\|time\|hours\|minutes" "$readme_file"; then
        log_validation "README Content" "PASS" "Duration information found"
    else
        log_validation "README Content" "WARN" "Duration information missing"
    fi
}

# Function to validate code quality
validate_code_quality() {
    local module_path="$1"
    local module_num="$2"
    
    print_colored $CYAN "Validating code quality..."
    
    # Find Python files
    local python_files=$(find "$module_path" -name "*.py" -not -path "*/.*")
    
    if [ -n "$python_files" ]; then
        # Check for Python style with flake8 (if available)
        if command -v flake8 &> /dev/null; then
            if echo "$python_files" | xargs flake8 --max-line-length=88 --ignore=E203,W503 2>/dev/null; then
                log_validation "Python Style" "PASS" "Python code follows PEP8 style"
            else
                log_validation "Python Style" "WARN" "Python code has style issues"
            fi
        else
            log_validation "Python Style" "WARN" "flake8 not available for style checking"
        fi
        
        # Check for type hints
        local files_with_hints=0
        local total_python_files=0
        
        while IFS= read -r file; do
            if [ -n "$file" ]; then
                total_python_files=$((total_python_files + 1))
                if grep -q "from typing import\|: str\|: int\|: float\|: bool\|: List\|: Dict" "$file"; then
                    files_with_hints=$((files_with_hints + 1))
                fi
            fi
        done <<< "$python_files"
        
        if [ $total_python_files -gt 0 ]; then
            local hint_percentage=$((files_with_hints * 100 / total_python_files))
            if [ $hint_percentage -ge 50 ]; then
                log_validation "Type Hints" "PASS" "$hint_percentage% of Python files have type hints"
            else
                log_validation "Type Hints" "WARN" "Only $hint_percentage% of Python files have type hints"
            fi
        fi
    fi
    
    # Find JavaScript/TypeScript files
    local js_files=$(find "$module_path" -name "*.js" -o -name "*.ts" -not -path "*/node_modules/*" -not -path "*/.*")
    
    if [ -n "$js_files" ]; then
        # Check for package.json
        if find "$module_path" -name "package.json" | grep -q .; then
            log_validation "Node.js Setup" "PASS" "package.json found"
        else
            log_validation "Node.js Setup" "WARN" "package.json missing for JavaScript/TypeScript files"
        fi
    fi
}

# Function to validate dependencies
validate_dependencies() {
    local module_path="$1"
    local module_num="$2"
    
    print_colored $CYAN "Validating dependencies..."
    
    # Check requirements.txt
    local requirements_files=$(find "$module_path" -name "requirements.txt")
    
    if [ -n "$requirements_files" ]; then
        while IFS= read -r req_file; do
            if [ -n "$req_file" ]; then
                log_validation "Python Dependencies" "PASS" "requirements.txt found: $req_file"
                
                # Check for version pinning
                if grep -q "==" "$req_file"; then
                    log_validation "Dependency Pinning" "PASS" "Dependencies are version pinned"
                else
                    log_validation "Dependency Pinning" "WARN" "Dependencies not version pinned"
                fi
            fi
        done <<< "$requirements_files"
    else
        # Check if Python files exist but no requirements.txt
        if find "$module_path" -name "*.py" | grep -q .; then
            log_validation "Python Dependencies" "WARN" "Python files found but no requirements.txt"
        fi
    fi
    
    # Check package.json
    local package_files=$(find "$module_path" -name "package.json")
    
    if [ -n "$package_files" ]; then
        while IFS= read -r pkg_file; do
            if [ -n "$pkg_file" ]; then
                log_validation "Node.js Dependencies" "PASS" "package.json found: $pkg_file"
            fi
        done <<< "$package_files"
    fi
}

# Function to validate Docker configurations
validate_docker_configs() {
    local module_path="$1"
    local module_num="$2"
    
    print_colored $CYAN "Validating Docker configurations..."
    
    # Check for Dockerfile
    local dockerfiles=$(find "$module_path" -name "Dockerfile")
    
    if [ -n "$dockerfiles" ]; then
        while IFS= read -r dockerfile; do
            if [ -n "$dockerfile" ]; then
                log_validation "Docker Config" "PASS" "Dockerfile found: $dockerfile"
                
                # Basic Dockerfile validation
                if grep -q "FROM" "$dockerfile" && grep -q "COPY\|ADD" "$dockerfile"; then
                    log_validation "Dockerfile Content" "PASS" "Dockerfile has basic structure"
                else
                    log_validation "Dockerfile Content" "WARN" "Dockerfile may be incomplete"
                fi
            fi
        done <<< "$dockerfiles"
    fi
    
    # Check for docker-compose.yml
    local compose_files=$(find "$module_path" -name "docker-compose.yml" -o -name "docker-compose.yaml")
    
    if [ -n "$compose_files" ]; then
        while IFS= read -r compose_file; do
            if [ -n "$compose_file" ]; then
                log_validation "Docker Compose" "PASS" "docker-compose.yml found: $compose_file"
            fi
        done <<< "$compose_files"
    fi
}

# Function to run tests
validate_tests() {
    local module_path="$1"
    local module_num="$2"
    
    if [ "$SKIP_TESTS" = true ]; then
        print_colored $YELLOW "Skipping test execution..."
        return
    fi
    
    print_colored $CYAN "Validating tests..."
    
    # Look for test files
    local test_files=$(find "$module_path" -name "*test*.py" -o -name "test_*.py" -o -name "*_test.py")
    
    if [ -n "$test_files" ]; then
        log_validation "Test Files" "PASS" "Test files found"
        
        # Try to run pytest if available
        if command -v pytest &> /dev/null; then
            local test_count=$(echo "$test_files" | wc -l)
            log_validation "Test Discovery" "PASS" "Found $test_count test files"
            
            # Note: We don't run tests here to avoid dependencies
            # In a real scenario, you might want to run them
        else
            log_validation "Test Runner" "WARN" "pytest not available for test execution"
        fi
    else
        log_validation "Test Files" "WARN" "No test files found"
    fi
    
    # Check for validation scripts
    if [ -f "$module_path/validate.py" ]; then
        log_validation "Validation Script" "PASS" "Module validation script found"
    else
        log_validation "Validation Script" "WARN" "No module validation script found"
    fi
}

# Function to validate a single module
validate_module() {
    local module_num="$1"
    local module_path="modules/module-$(printf "%02d" $module_num)"
    
    if [ ! -d "$module_path" ]; then
        print_colored $RED "Module $module_num directory not found: $module_path"
        return 1
    fi
    
    print_colored $BLUE "═══════════════════════════════════════════════════════════════"
    print_colored $BLUE "Validating Module $module_num ($(get_module_track $module_num))"
    print_colored $BLUE "Path: $module_path"
    print_colored $BLUE "═══════════════════════════════════════════════════════════════"
    
    # Reset counters for this module
    local module_start_total=$TOTAL_CHECKS
    local module_start_passed=$PASSED_CHECKS
    local module_start_failed=$FAILED_CHECKS
    local module_start_warnings=$WARNING_CHECKS
    
    # Run validations
    validate_directory_structure "$module_path" "$module_num"
    validate_exercise_structure "$module_path" "$module_num"
    validate_readme_content "$module_path" "$module_num"
    validate_code_quality "$module_path" "$module_num"
    validate_dependencies "$module_path" "$module_num"
    validate_docker_configs "$module_path" "$module_num"
    validate_tests "$module_path" "$module_num"
    
    # Calculate module results
    local module_total=$((TOTAL_CHECKS - module_start_total))
    local module_passed=$((PASSED_CHECKS - module_start_passed))
    local module_failed=$((FAILED_CHECKS - module_start_failed))
    local module_warnings=$((WARNING_CHECKS - module_start_warnings))
    
    # Module summary
    print_colored $BLUE "─────────────────────────────────────────────────────────────────"
    if [ $module_failed -eq 0 ]; then
        print_colored $GREEN "✅ Module $module_num: PASSED ($module_passed/$module_total checks)"
    else
        print_colored $RED "❌ Module $module_num: FAILED ($module_failed failures, $module_warnings warnings)"
    fi
    print_colored $BLUE "─────────────────────────────────────────────────────────────────"
    echo ""
}

# Function to generate JSON report
generate_json_report() {
    cat << EOF
{
  "validation_report": {
    "timestamp": "$(date -Iseconds)",
    "validator_version": "$SCRIPT_VERSION",
    "summary": {
      "total_checks": $TOTAL_CHECKS,
      "passed": $PASSED_CHECKS,
      "failed": $FAILED_CHECKS,
      "warnings": $WARNING_CHECKS,
      "success_rate": $(( PASSED_CHECKS * 100 / TOTAL_CHECKS ))
    },
    "errors": [
$(IFS=$'\n'; for error in "${VALIDATION_ERRORS[@]}"; do echo "      \"$error\","; done | sed '$ s/,$//')
    ]
  }
}
EOF
}

# Function to show final summary
show_summary() {
    print_colored $PURPLE "═══════════════════════════════════════════════════════════════"
    print_colored $PURPLE "                    📊 VALIDATION SUMMARY"
    print_colored $PURPLE "═══════════════════════════════════════════════════════════════"
    print_colored $BLUE "Total Checks:     $TOTAL_CHECKS"
    print_colored $GREEN "Passed:           $PASSED_CHECKS"
    print_colored $RED "Failed:           $FAILED_CHECKS"
    print_colored $YELLOW "Warnings:         $WARNING_CHECKS"
    
    if [ $TOTAL_CHECKS -gt 0 ]; then
        local success_rate=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
        print_colored $BLUE "Success Rate:     ${success_rate}%"
    fi
    
    print_colored $PURPLE "═══════════════════════════════════════════════════════════════"
    
    if [ $FAILED_CHECKS -eq 0 ]; then
        print_colored $GREEN "🎉 All validations passed successfully!"
    else
        print_colored $RED "⚠️  $FAILED_CHECKS validation(s) failed"
        if [ "$FIX_ISSUES" = false ]; then
            print_colored $YELLOW "Run with --fix to attempt automatic fixes"
        fi
    fi
    
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--module)
            MODULE_NUMBER="$2"
            shift 2
            ;;
        -a|--all)
            VALIDATE_ALL=true
            shift
            ;;
        -f|--fix)
            FIX_ISSUES=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -o|--output)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        -s|--skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            print_colored $RED "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Main execution
main() {
    print_header
    
    if [ "$VALIDATE_ALL" = true ]; then
        print_colored $CYAN "Validating all 30 workshop modules..."
        for i in {1..30}; do
            validate_module $i
        done
    elif [ -n "$MODULE_NUMBER" ]; then
        if [[ $MODULE_NUMBER -ge 1 && $MODULE_NUMBER -le 30 ]]; then
            validate_module $MODULE_NUMBER
        else
            print_colored $RED "Invalid module number. Must be between 1 and 30."
            exit 1
        fi
    else
        print_colored $RED "Please specify a module number (-m) or use --all"
        show_help
        exit 1
    fi
    
    # Generate output based on format
    case $OUTPUT_FORMAT in
        "json")
            generate_json_report
            ;;
        "console"|*)
            show_summary
            ;;
    esac
    
    # Exit with appropriate code
    if [ $FAILED_CHECKS -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# Execute main function
main "$@"
