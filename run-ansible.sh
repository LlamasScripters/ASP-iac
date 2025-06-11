#!/bin/sh

# Get the IPs from the Terraform output
MANAGER_IP=$(terraform -chdir=terraform/envs/prod output -raw manager_ip)
WORKER1_IP=$(terraform -chdir=terraform/envs/prod output -raw worker1_ip)
WORKER2_IP=$(terraform -chdir=terraform/envs/prod output -raw worker2_ip)

echo "Manager IP: $MANAGER_IP"
echo "Worker1 IP: $WORKER1_IP"
echo "Worker2 IP: $WORKER2_IP"

ansible() {
    docker exec -it ansible ansible "$@"
}

ansible_playbook() {
    docker exec -it ansible ansible-playbook "$@"
}

# Replace the IPs in the inventory template
MANAGER_IP=$MANAGER_IP WORKER1_IP=$WORKER1_IP WORKER2_IP=$WORKER2_IP envsubst < ansible/templates/inventory_template.yml > ansible/inventory.yml

# Start the Ansible container
docker compose up -d

# Ping all hosts
ansible all -m ping

# Install Docker
ansible_playbook playbooks/install_docker.yaml

# Stop the Ansible container
docker compose down