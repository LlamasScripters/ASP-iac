#!/bin/bash

# Infrastructure as Code Deployment Script
# Manages Terraform infrastructure and Ansible configuration

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENV=""
RESET=false
DRY_RUN=false
VERBOSE=false
TAGS=""
SKIP_TERRAFORM=false
SKIP_ANSIBLE=false
HELP=false

usage() {
    printf "%bInfrastructure as Code Deployment Script%b\n\n" "$BLUE" "$NC"
    printf "%bUSAGE:%b\n" "$GREEN" "$NC"
    printf "    deploy.sh [OPTIONS]\n\n"
    printf "%bREQUIRED OPTIONS:%b\n" "$GREEN" "$NC"
    printf "    -e, --environment ENV    Specify the environment (production|staging)\n\n"
    printf "%bOPTIONAL FLAGS:%b\n" "$GREEN" "$NC"
    printf "    -r, --reset             Reset infrastructure (destroy then redeploy)\n"
    printf "    -d, --dry-run           Show what would be deployed without executing\n"
    printf "    -v, --verbose           Enable verbose output\n"
    printf "    -h, --help              Show this help message\n\n"
    printf "%bADVANCED OPTIONS:%b\n" "$GREEN" "$NC"
    printf "    -t, --tags TAGS         Run only specific Ansible tags (comma-separated)\n"
    printf "    --skip-terraform        Skip Terraform deployment, run only Ansible\n"
    printf "    --skip-ansible          Skip Ansible deployment, run only Terraform\n\n"
    printf "%bEXAMPLES:%b\n" "$GREEN" "$NC"
    printf "    %b# Basic deployment%b\n" "$YELLOW" "$NC"
    printf "    ./deploy.sh --environment production\n\n"
    printf "    %b# Reset and redeploy with verbose output%b\n" "$YELLOW" "$NC"
    printf "    ./deploy.sh -e staging --reset --verbose\n\n"
    printf "    %b# Deploy only monitoring stack%b\n" "$YELLOW" "$NC"
    printf "    ./deploy.sh -e production --tags monitoring --skip-terraform\n\n"
    printf "    %b# Dry run to see what would be deployed%b\n" "$YELLOW" "$NC"
    printf "    ./deploy.sh -e production --dry-run\n\n"
    printf "    %b# Deploy only infrastructure%b\n" "$YELLOW" "$NC"
    printf "    ./deploy.sh -e production --skip-ansible\n\n"
    printf "%bENVIRONMENTS:%b\n" "$GREEN" "$NC"
    printf "    production              Production environment (terraform/envs/production)\n"
    printf "    staging                 Staging environment (terraform/envs/staging)\n\n"
    printf "%bAVAILABLE ANSIBLE TAGS:%b\n" "$GREEN" "$NC"
    printf "    common                  Base server setup (Docker, users, security)\n"
    printf "    proxy                   Traefik reverse proxy\n"
    printf "    monitoring              Prometheus, Grafana, AlertManager stack\n"
    printf "    asphub                  Main application with PostgreSQL\n"
    printf "    backup                  Backup system with 3-2-1 strategy\n"
    printf "    uptime-kuma             Uptime monitoring dashboard\n\n"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--environment)
                ENV="$2"
                shift 2
                ;;
            -r|--reset)
                RESET=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -t|--tags)
                TAGS="$2"
                shift 2
                ;;
            --skip-terraform)
                SKIP_TERRAFORM=true
                shift
                ;;
            --skip-ansible)
                SKIP_ANSIBLE=true
                shift
                ;;
            -h|--help)
                HELP=true
                shift
                ;;
            -*)
                echo -e "${RED}Error: Unknown option $1${NC}" >&2
                usage
                exit 1
                ;;
            *)
                echo -e "${RED}Error: Unexpected argument $1${NC}" >&2
                usage
                exit 1
                ;;
        esac
    done
}

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Validation functions
validate_environment() {
    if [[ -z "${ENV}" ]]; then
        log_error "Environment is required. Use -e or --environment."
        usage
        exit 1
    fi
    
    local env_lower=$(echo "$ENV" | tr '[:upper:]' '[:lower:]')
    if [[ "$env_lower" != "production" && "$env_lower" != "staging" ]]; then
        log_error "Invalid environment '$ENV'. Must be 'production' or 'staging'."
        usage
        exit 1
    fi
    
    ENV="$env_lower"
}

validate_dependencies() {
    local missing_deps=()
    
    command -v terraform >/dev/null 2>&1 || missing_deps+=("terraform")
    command -v ansible-playbook >/dev/null 2>&1 || missing_deps+=("ansible-playbook")
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        exit 1
    fi
}

validate_directories() {
    local terraform_dir="terraform/envs/$ENV"
    local ansible_dir="ansible"
    
    if [[ ! -d "$terraform_dir" ]]; then
        log_error "Terraform directory not found: $terraform_dir"
        exit 1
    fi
    
    if [[ ! -d "$ansible_dir" ]]; then
        log_error "Ansible directory not found: $ansible_dir"
        exit 1
    fi
    
    if [[ ! -f "$ansible_dir/inventory.yml" ]]; then
        log_error "Ansible inventory not found: $ansible_dir/inventory.yml"
        exit 1
    fi
}

# Parse arguments
parse_args "$@"

# Show help if requested
if [[ "$HELP" == true ]]; then
    usage
    exit 0
fi

# Validate inputs
validate_environment
validate_dependencies
validate_directories

# Set directories
TERRAFORM_DIR="terraform/envs/$ENV"
ANSIBLE_DIR="ansible"

# Display deployment configuration
log_info "Deployment Configuration:"
echo "  Environment: $ENV"
echo "  Reset Infrastructure: $RESET"
echo "  Dry Run: $DRY_RUN"
echo "  Verbose: $VERBOSE"
echo "  Skip Terraform: $SKIP_TERRAFORM"
echo "  Skip Ansible: $SKIP_ANSIBLE"
[[ -n "$TAGS" ]] && echo "  Ansible Tags: $TAGS"
echo

# Dry run mode - show Terraform plan and run Ansible in check mode
if [[ "$DRY_RUN" == true ]]; then
    log_warning "DRY RUN MODE - NO changes will be made"
    
    # Terraform dry run - show plan only
    if [[ "$SKIP_TERRAFORM" != true ]]; then
        log_info "Running Terraform plan (dry run)..."
        terraform -chdir="$TERRAFORM_DIR" init
        
        if [[ "$RESET" == true ]]; then
            log_info "Would destroy infrastructure (showing destroy plan):"
            terraform -chdir="$TERRAFORM_DIR" plan -destroy
        fi
        
        log_info "Terraform plan for deployment:"
        terraform -chdir="$TERRAFORM_DIR" plan
        echo
    fi
    
    # Ansible dry run - use check mode
    if [[ "$SKIP_ANSIBLE" != true ]]; then
        log_warning "Ansible dry run requires existing infrastructure to connect to servers"
        log_info "Running Ansible in check mode (dry run)..."
        
        # Update inventory for dry run
        sed -i "s|project_path: .*|project_path: ../terraform/envs/$ENV|g" "$ANSIBLE_DIR/inventory.yml"
        
        # Build Ansible command with check mode
        local ansible_cmd=("ansible-playbook" "playbooks/site.yml" "-i" "inventory.yml" "--check" "--diff")
        
        [[ "$VERBOSE" == true ]] && ansible_cmd+=("-v")
        [[ -n "$TAGS" ]] && ansible_cmd+=("--tags" "$TAGS")
        
        log_info "Ansible command: ${ansible_cmd[*]}"
        echo "Note: If infrastructure doesn't exist, Ansible will fail to connect to servers"
        
        cd "$ANSIBLE_DIR"
        "${ansible_cmd[@]}" || {
            log_warning "Ansible dry run failed - this is expected if infrastructure doesn't exist"
            log_info "Deploy infrastructure first, then run dry run for configuration changes"
        }
        echo
    fi
    
    log_success "Dry run completed. Use without --dry-run to apply these changes."
    exit 0
fi

# Terraform operations
if [[ "$SKIP_TERRAFORM" != true ]]; then
    log_info "Initializing Terraform..."
    terraform -chdir="$TERRAFORM_DIR" init
    
    # Reset infrastructure if requested
    if [[ "$RESET" == true ]]; then
        log_warning "Reset flag detected. Destroying existing infrastructure..."
        terraform -chdir="$TERRAFORM_DIR" destroy -auto-approve
        log_success "Infrastructure destroyed. Proceeding with fresh deployment..."
    fi
    
    log_info "Applying Terraform configuration..."
    terraform -chdir="$TERRAFORM_DIR" apply -auto-approve
    log_success "Terraform deployment completed"
else
    log_info "Skipping Terraform operations"
fi

# Ansible operations
if [[ "$SKIP_ANSIBLE" != true ]]; then
    log_info "Updating Terraform inventory path for Ansible..."
    sed -i "s|project_path: .*|project_path: ../terraform/envs/$ENV|g" "$ANSIBLE_DIR/inventory.yml"
    
    log_info "Waiting for infrastructure to be ready..."
    sleep 5
    
    # Build Ansible command
    ansible_cmd=("ansible-playbook" "playbooks/site.yml" "-i" "inventory.yml")
    
    [[ "$VERBOSE" == true ]] && ansible_cmd+=("-v")
    [[ -n "$TAGS" ]] && ansible_cmd+=("--tags" "$TAGS")
    
    log_info "Running Ansible playbook with dynamic inventory..."
    [[ "$VERBOSE" == true ]] && log_info "Command: ${ansible_cmd[*]}"
    
    cd "$ANSIBLE_DIR"
    "${ansible_cmd[@]}"
    
    log_success "Ansible deployment completed"
else
    log_info "Skipping Ansible operations"
fi

log_success "Deployment completed successfully!"

# Display useful information
if [[ "$ENV" == "production" ]]; then
    echo
    log_info "Production URLs:"
    echo "  - Grafana: https://grafana.mchegdali.cloud"
    echo "  - Prometheus: https://prometheus.mchegdali.cloud"
    echo "  - AlertManager: https://alertmanager.mchegdali.cloud"
    echo "  - ASPHub: https://mchegdali.cloud"
    echo "  - Traefik: https://traefik.mchegdali.cloud"
    echo "  - Uptime Kuma: https://uptime.mchegdali.cloud"
fi