#!/bin/bash

# Script to switch Traefik back to production Let's Encrypt certificates
# Run this after 2025-07-03 00:42:22 UTC when the rate limit expires

echo "Switching Traefik to production Let's Encrypt certificates..."

# Remove the staging CA server line from the compose file
sed -i '/acme.caserver=https:\/\/acme-staging-v02.api.letsencrypt.org\/directory/d' \
    ansible/playbooks/roles/proxy/files/compose.yml

# Update the comment
sed -i 's/# Configure Let.* (using staging to bypass rate limit)/# Configure Let'\''s Encrypt certificate resolver/' \
    ansible/playbooks/roles/proxy/files/compose.yml

echo "Configuration updated. Deploying changes..."

# Redeploy the proxy service
cd ansible && ansible-playbook playbooks/site.yml --tags proxy

echo "Clearing staging certificates to force production certificate generation..."

# Clear existing certificates
ssh asphub@$(terraform -chdir=terraform/envs/production output -raw manager_ip) \
    "docker exec \$(docker ps | grep traefik | awk '{print \$1}') rm -rf /letsencrypt/acme.json"

echo "Done! Production certificates should be generated shortly."
echo "Check the logs with: ssh asphub@\$(terraform -chdir=terraform/envs/production output -raw manager_ip) \"docker service logs proxy_traefik --tail 20\""