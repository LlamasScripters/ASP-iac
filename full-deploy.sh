#!/bin/bash

usage() {
    echo "Usage: full-deploy.sh -e <environment> [-r]"
    echo "  -e: specify the environment (production or staging)"
    echo "  -r: reset the infrastructure (destroy then redeploy)"
    return 1
}

# Reset OPTIND for getopts, which is good practice
OPTIND=1

ENV=""
RESET=false
while getopts ":e:r" opt; do
  case ${opt} in
    e)
      ENV=$OPTARG
      ;;
    r)
      RESET=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" 1>&2
      usage
      return 1
      ;;
    :)
      echo "Invalid option: -$OPTARG requires an argument" 1>&2
      usage
      return 1
      ;;
  esac
done
shift $((OPTIND -1))

if [ -z "${ENV}" ]; then
    usage
    return 1
fi

ENV_LOWER=$(echo "$ENV" | tr '[:upper:]' '[:lower:]')

if [ "$ENV_LOWER" != "production" ] && [ "$ENV_LOWER" != "staging" ]; then
    echo "Error: Invalid environment specified. Must be 'production' or 'staging'."
    usage
    return 1
fi

TERRAFORM_DIR="terraform/envs/$ENV_LOWER"
ANSIBLE_DIR="ansible"

terraform -chdir=$TERRAFORM_DIR init

# If reset flag is set, destroy existing infrastructure first
if [ "$RESET" = true ]; then
    echo "Reset flag detected. Destroying existing infrastructure..."
    terraform -chdir=$TERRAFORM_DIR destroy -auto-approve
    echo "Infrastructure destroyed. Proceeding with fresh deployment..."
fi

terraform -chdir=$TERRAFORM_DIR apply -auto-approve

MANAGER_IP=$(terraform -chdir="$TERRAFORM_DIR" output -raw manager_ip)
WORKER1_IP=$(terraform -chdir="$TERRAFORM_DIR" output -raw worker1_ip)
WORKER2_IP=$(terraform -chdir="$TERRAFORM_DIR" output -raw worker2_ip)

cd $ANSIBLE_DIR
./run-ansible.sh --manager-ip $MANAGER_IP --worker1-ip $WORKER1_IP --worker2-ip $WORKER2_IP