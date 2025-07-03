#!/bin/bash

usage() {
    echo "Usage: source $0 -e <environment>"
    echo "  -e: specify the environment (production or staging)"
    return 1
}

# Reset OPTIND for getopts, which is good practice
OPTIND=1

ENV=""
while getopts ":e:" opt; do
  case ${opt} in
    e)
      ENV=$OPTARG
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

if [ ! -d "$TERRAFORM_DIR" ]; then
    echo "Error: Directory $TERRAFORM_DIR does not exist."
    return 1
fi

echo "Setting environment variables from Terraform outputs in $TERRAFORM_DIR..."
terraform_output=$(terraform -chdir=$TERRAFORM_DIR output -json)

export MANAGER_IP=$(echo $terraform_output | jq -r '.manager_ip.value')
export WORKER1_IP=$(echo $terraform_output | jq -r '.worker1_ip.value')
export WORKER2_IP=$(echo $terraform_output | jq -r '.worker2_ip.value')

echo "Environment variables set."

unset ENV ENV_LOWER TERRAFORM_DIR usage opt