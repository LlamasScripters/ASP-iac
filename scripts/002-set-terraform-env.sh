#!/bin/bash

# Default path, can be overridden with --path argument
# To use from root directory: ./scripts/002-set-terraform-env.sh --path ./terraform/envs/prod
TERRAFORM_PATH="./terraform/envs/prod"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --path)
            TERRAFORM_PATH="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ ! -d "$TERRAFORM_PATH" ]; then
    echo "Erreur: Le dossier Terraform n'existe pas: $TERRAFORM_PATH"
    exit 1
fi

# Check lockfile to know if Terraform has been initialized
if [ ! -f "$TERRAFORM_PATH/.terraform.lock.hcl" ]; then
    echo "Erreur: Terraform n'est pas initialisé dans $TERRAFORM_PATH"
    exit 2
fi

cd "$TERRAFORM_PATH"

export TF_OUTPUT_MANAGER_IP=$(terraform output -raw manager_ip)
export TF_OUTPUT_WORKER1_IP=$(terraform output -raw worker1_ip)
export TF_OUTPUT_WORKER2_IP=$(terraform output -raw worker2_ip)

echo "TF_OUTPUT_MANAGER_IP=$TF_OUTPUT_MANAGER_IP"
echo "TF_OUTPUT_WORKER1_IP=$TF_OUTPUT_WORKER1_IP"
echo "TF_OUTPUT_WORKER2_IP=$TF_OUTPUT_WORKER2_IP"