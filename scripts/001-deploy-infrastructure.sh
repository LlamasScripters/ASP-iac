#!/bin/bash

if [ ! -d "./terraform/envs/prod" ]; then
    echo "Erreur: Le dossier terraform/envs/prod n'existe pas"
    exit 1
fi

# Check HCLOUD_TOKEN is set
if [ -z "$HCLOUD_TOKEN" ]; then
    echo "Erreur: La variable d'environnement HCLOUD_TOKEN n'est pas définie"
    exit 1
fi

cd ./terraform/envs/prod

if [ ! -d ".terraform" ]; then
    echo "Initialisation de Terraform..."
    terraform init
fi

terraform plan -out tfplan
terraform apply tfplan