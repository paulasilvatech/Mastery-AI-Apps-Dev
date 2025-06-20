#!/bin/bash

# Module 11: Cleanup Resources Script
# Safely removes Docker resources and cleans up the environment

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Print functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Banner
echo -e "${BLUE}"
echo "╔════════════════════════════════════════════╗"
echo "║    Module 11: Resource Cleanup Script      ║"
echo "╚════════════════════════════════════════════╝"
echo -e "${NC}"

# Parse arguments
FORCE=false
CLEAN_ALL=false
EXERCISE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--force)
            FORCE=true
            shift
            ;;
        -a|--all)
            CLEAN_ALL=true
            shift
            ;;
        -e|--exercise)
            EXERCISE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -f, --force       Force cleanup without confirmation"
            echo "  -a, --all         Clean all resources including images"
            echo "  -e, --exercise    Clean specific exercise (1, 2, or 3)"
            echo "  -h, --help        Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Confirmation
if [ "$FORCE" != true ]; then
    print_warning "This will remove Docker containers, networks, and volumes for Module 11."
    read -p "Are you sure you want to continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Cleanup cancelled."
        exit 0
    fi
fi

# Function to clean Docker Compose project
clean_compose_project() {
    local dir=$1
    local project_name=$2
    
    if [ -f "$dir/docker-compose.yml" ]; then
        print_info "Cleaning $project_name..."
        cd "$dir"
        docker compose down -v --remove-orphans 2>/dev/null || true
        cd - > /dev/null
        print_success "$project_name cleaned"
    fi
}

# Stop all module services
print_info "Stopping all Module 11 services..."

# Clean specific exercise or all
if [ -n "$EXERCISE" ]; then
    case $EXERCISE in
        1)
            clean_compose_project "exercises/exercise1-foundation" "Exercise 1"
            ;;
        2)
            clean_compose_project "exercises/exercise2-application" "Exercise 2"
            ;;
        3)
            clean_compose_project "exercises/exercise3-mastery" "Exercise 3"
            ;;
        *)
            print_error "Invalid exercise number: $EXERCISE"
            exit 1
            ;;
    esac
else
    # Clean all exercises
    for exercise_dir in exercises/*/; do
        if [ -d "$exercise_dir" ]; then
            exercise_name=$(basename "$exercise_dir")
            clean_compose_project "$exercise_dir" "$exercise_name"
        fi
    done
fi

# Clean sample infrastructure
if [ -f "docker-compose.sample.yml" ]; then
    print_info "Cleaning sample infrastructure..."
    docker compose -f docker-compose.sample.yml down -v --remove-orphans 2>/dev/null || true
fi

# Remove specific containers
print_info "Removing Module 11 containers..."
docker ps -a --filter "name=user-service" --format "{{.ID}}" | xargs -r docker rm -f 2>/dev/null || true
docker ps -a --filter "name=product-service" --format "{{.ID}}" | xargs -r docker rm -f 2>/dev/null || true
docker ps -a --filter "name=order-service" --format "{{.ID}}" | xargs -r docker rm -f 2>/dev/null || true
docker ps -a --filter "name=notification-service" --format "{{.ID}}" | xargs -r docker rm -f 2>/dev/null || true
docker ps -a --filter "name=inventory-service" --format "{{.ID}}" | xargs -r docker rm -f 2>/dev/null || true
docker ps -a --filter "name=api-gateway" --format "{{.ID}}" | xargs -r docker rm -f 2>/dev/null || true
docker ps -a --filter "name=saga-orchestrator" --format "{{.ID}}" | xargs -r docker rm -f 2>/dev/null || true

# Remove infrastructure containers
docker ps -a --filter "name=rabbitmq" --format "{{.ID}}" | xargs -r docker rm -f 2>/dev/null || true
docker ps -a --filter "name=redis" --format "{{.ID}}" | xargs -r docker rm -f 2>/dev/null || true
docker ps -a --filter "name=postgres" --format "{{.ID}}" | xargs -r docker rm -f 2>/dev/null || true
docker ps -a --filter "name=prometheus" --format "{{.ID}}" | xargs -r docker rm -f 2>/dev/null || true
docker ps -a --filter "name=grafana" --format "{{.ID}}" | xargs -r docker rm -f 2>/dev/null || true

print_success "Containers removed"

# Remove networks
print_info "Removing Docker networks..."
docker network rm microservices-network 2>/dev/null || true
print_success "Networks removed"

# Remove volumes
print_info "Removing Docker volumes..."
docker volume ls --filter "name=postgres_data" --format "{{.Name}}" | xargs -r docker volume rm 2>/dev/null || true
docker volume ls --filter "name=redis_data" --format "{{.Name}}" | xargs -r docker volume rm 2>/dev/null || true
docker volume ls --filter "name=rabbitmq_data" --format "{{.Name}}" | xargs -r docker volume rm 2>/dev/null || true
docker volume ls --filter "name=prometheus_data" --format "{{.Name}}" | xargs -r docker volume rm 2>/dev/null || true
docker volume ls --filter "name=grafana_data" --format "{{.Name}}" | xargs -r docker volume rm 2>/dev/null || true
print_success "Volumes removed"

# Remove images if requested
if [ "$CLEAN_ALL" = true ]; then
    print_info "Removing Docker images..."
    docker images --filter "reference=*service*" --format "{{.ID}}" | xargs -r docker rmi -f 2>/dev/null || true
    docker images --filter "reference=*gateway*" --format "{{.ID}}" | xargs -r docker rmi -f 2>/dev/null || true
    print_success "Images removed"
    
    # Clean build cache
    print_info "Cleaning Docker build cache..."
    docker builder prune -f 2>/dev/null || true
    print_success "Build cache cleaned"
fi

# Clean Python artifacts
print_info "Cleaning Python artifacts..."
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true
find . -type f -name "*.pyo" -delete 2>/dev/null || true
find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name ".mypy_cache" -exec rm -rf {} + 2>/dev/null || true
find . -type f -name ".coverage" -delete 2>/dev/null || true
print_success "Python artifacts cleaned"

# Clean logs
if [ -d "logs" ]; then
    print_info "Cleaning log files..."
    rm -rf logs/*
    print_success "Logs cleaned"
fi

# Summary
echo -e "\n${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        Cleanup Completed Successfully!      ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo

# Show remaining Docker resources
print_info "Remaining Docker resources:"
echo -e "\nContainers:"
docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep -E "(user-|product-|order-|notification-|inventory-|api-gateway|saga-)" || echo "  None"

echo -e "\nNetworks:"
docker network ls --format "table {{.Name}}\t{{.Driver}}" | grep microservices || echo "  None"

echo -e "\nVolumes:"
docker volume ls --format "table {{.Name}}\t{{.Driver}}" | grep -E "(postgres_|redis_|rabbitmq_|prometheus_|grafana_)" || echo "  None"

# Disk usage
echo -e "\nDocker disk usage:"
docker system df

# Suggestions
echo -e "\n${BLUE}Suggestions:${NC}"
echo "- To remove all Docker resources: docker system prune -a"
echo "- To start fresh: ./scripts/setup-module-11.sh"
echo "- To check disk space: df -h"

print_success "Module 11 resources have been cleaned up!"