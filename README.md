# ASP-iac : Infrastructure as Code pour ASPHub

![Infrastructure Status](https://img.shields.io/badge/Infrastructure-Production%20Ready-green)
![Terraform](https://img.shields.io/badge/Terraform-1.x-blue)
![Ansible](https://img.shields.io/badge/Ansible-11.x-red)
![Docker Swarm](https://img.shields.io/badge/Docker%20Swarm-Enabled-blue)

## 📋 Table des matières

- [Vue d'ensemble](#vue-densemble)
- [Architecture](#architecture)
- [Prérequis](#prérequis)
- [Installation et configuration](#installation-et-configuration)
- [Déploiement](#déploiement)
- [Services déployés](#services-déployés)
- [Surveillance et monitoring](#surveillance-et-monitoring)
- [Gestion des environnements](#gestion-des-environnements)
- [Maintenance](#maintenance)
- [Troubleshooting](#troubleshooting)
- [Contribution](#contribution)

## 🎯 Vue d'ensemble

Ce projet fournit une infrastructure complète en **Infrastructure as Code (IaC)** pour déployer l'application **ASPHub** sur le cloud. Il utilise une architecture moderne basée sur Docker Swarm, avec un déploiement automatisé via Terraform et Ansible.

### 🏗️ Stack technologique

- **Infrastructure** : Terraform + Hetzner Cloud + OVH DNS
- **Orchestration** : Docker Swarm (1 manager + 2 workers)
- **Configuration** : Ansible avec rôles modulaires
- **Reverse Proxy** : Traefik v3.4 avec SSL automatique (Let's Encrypt)
- **Monitoring** : Prometheus + Grafana + AlertManager
- **Stockage** : PostgreSQL + MinIO
- **Sécurité** : Certificats SSL automatiques, authentification, secrets Docker

## 🏛️ Architecture

### Infrastructure Cloud

```
┌─────────────────────────────────────────────────────────────┐
│                     Hetzner Cloud (nbg1)                   │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │   Manager Node  │  │   Worker Node 1 │  │ Worker Node 2│ │
│  │  192.168.0.100  │  │  192.168.0.101  │  │192.168.0.102 │ │
│  │     (cx22)      │  │     (cx22)      │  │    (cx22)    │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                      OVH DNS                                │
├─────────────────────────────────────────────────────────────┤
│  • mchegdali.cloud (domaine principal)                      │
│  • grafana.mchegdali.cloud                                  │
│  • prometheus.mchegdali.cloud                               │
│  • traefik.mchegdali.cloud                                  │
│  • alertmanager.mchegdali.cloud                             │
└─────────────────────────────────────────────────────────────┘
```

### Architecture logicielle

```
┌────────────────────────────────────────────────────────────┐
│                    Docker Swarm Cluster                    │
├────────────────────────────────────────────────────────────┤
│  Manager Node (192.168.0.100)                              │
│  ├── Traefik (Reverse Proxy + SSL)                         │
│  ├── Prometheus (Métriques)                                │
│  ├── Grafana (Dashboards)                                  │
│  ├── AlertManager (Alertes)                                │
│  └── Uptime Kuma (Monitoring services)                     │
│                                                            │
│  Worker Nodes (192.168.0.101-102)                          │
│  ├── ASPHub Client (Frontend React)                        │
│  ├── ASPHub Server (Backend Node.js)                       │
│  ├── PostgreSQL (Base de données)                          │
│  ├── MinIO (Stockage objets)                               │
│  ├── Node Exporter (Métriques système)                     │
│  └── cAdvisor (Métriques conteneurs)                       │
└────────────────────────────────────────────────────────────┘
```

### Flux de données

```
Internet → Traefik → [ASPHub Client|ASPHub Server] → PostgreSQL/MinIO
                           ↓
                    Prometheus ← Node Exporter/cAdvisor
                           ↓
                       Grafana → Dashboards
                           ↓
                    AlertManager → Notifications
                           ↓
                    Uptime Kuma → Services Monitoring
```

## 📋 Prérequis

### Outils requis

- **Terraform** ≥ 1.11.4
- **Ansible** ≥ 11.7.0
- **Python** ≥ 3.12
- **UV** (gestionnaire de paquets Python) (https://docs.astral.sh/uv/getting-started/installation/)
- **Git**

### Comptes cloud requis

1. **Hetzner Cloud**
   - Compte actif avec facturation configurée
   - Token API avec permissions complètes
   - Budget recommandé : ~30€/mois pour la production

2. **OVH**
   - Domaine enregistré (ex: `mchegdali.cloud`)
   - Accès API OVH configuré
   - Credentials OVH (Application Key, Secret, Consumer Key)

3. **Terraform Cloud**
   - Organisation : `moustaphachegdali`
   - Workspace configuré pour chaque environnement

### Variables d'environnement requises

```bash
# Hetzner Cloud
export HCLOUD_TOKEN="your-hetzner-token"

# Ansible vault passsword
export ANSIBLE_VAULT_PASS=

# OVH
export OVH_ENDPOINT="ovh-eu"
export OVH_APPLICATION_KEY="your-app-key"
export OVH_APPLICATION_SECRET="your-app-secret"
export OVH_CONSUMER_KEY="your-consumer-key"

# Github
export GITHUB_USERNAME=
export GITHUB_TOKEN=
```

## 🚀 Installation et configuration

### 1. Clonage du repository

```bash
git clone <repository-url>
cd ASP-iac
```

### 2. Installation des dépendances Python

```bash
# Avec UV (recommandé)
uv sync

# Ou avec pip
pip install -r requirements.txt
```

### 3. Installation des collections Ansible

```bash
cd ansible
ansible-galaxy collection install -r requirements.yml
```


### 4. Configuration des secrets Ansible

Les secrets sont stockés dans des fichiers vault chiffrés :

```bash
# Édition des secrets
ansible-vault edit ansible/playbooks/group_vars/all/vault_asphub.yml
ansible-vault edit ansible/playbooks/group_vars/all/vault_monitoring.yml
ansible-vault edit ansible/playbooks/group_vars/all/vault_proxy.yml
ansible-vault edit ansible/playbooks/group_vars/all/vault_backup.yml
```

## 🛠️ Déploiement

### Script de déploiement automatisé

Le projet inclut un script de déploiement complet avec de nombreuses options :

```bash
./deploy.sh --help
```

### Déploiement complet

#### Production
```bash
# Déploiement standard
./deploy.sh --environment production

# Avec logs détaillés
./deploy.sh --environment production --verbose

# Reset complet de l'infrastructure
./deploy.sh --environment production --reset --verbose
```

#### Staging
```bash
./deploy.sh --environment staging
```

### Déploiements partiels

#### Infrastructure seulement (Terraform)
```bash
./deploy.sh --environment production --skip-ansible
```

#### Configuration seulement (Ansible)
```bash
./deploy.sh --environment production --skip-terraform
```

#### Par tags Ansible
```bash
# Déploiement du monitoring uniquement
./deploy.sh --environment production --tags monitoring --skip-terraform

# Déploiement de l'application ASPHub
./deploy.sh --environment production --tags asphub --skip-terraform

# Configuration du proxy
./deploy.sh --environment production --tags proxy --skip-terraform
```

### Déploiement manuel étape par étape

#### 1. Infrastructure Terraform

```bash
cd terraform/envs/production
public_key=$(cat ~/.ssh/id_ed25519.pub) # adapter à votre configuration
terraform init

# Si environnement non déployé
terraform plan -var="ssh_public_key=$public_key" -out tfplan
terraform apply tfplan
```

#### 2. Configuration Ansible

```bash
cd ansible
ansible-playbook playbooks/site.yml
```

## 🖥️ Services déployés

### ASPHub (Application principale)

- **Client** : Application React frontend
  - URL : `https://mchegdali.cloud`
  - Déployé sur les workers

- **Server** : API Node.js backend
  - URL : `https://mchegdali.cloud/api`
  - Déployé sur les workers
  - Variables d'environnement via secrets Docker

- **PostgreSQL** : Base de données
  - Version configurée via variables
  - Configuration personnalisée
  - Données persistantes sur volumes Docker

- **MinIO** : Stockage d'objets
  - Compatible S3
  - Authentification via secrets
  - Stockage persistant

### Traefik (Reverse Proxy)

- **URL** : `https://traefik.mchegdali.cloud`
- **Fonctionnalités** :
  - SSL automatique (Let's Encrypt)
  - Redirection HTTP → HTTPS
  - Dashboard avec authentification
  - Métriques Prometheus
  - Load balancing automatique

### Stack de monitoring

#### Prometheus
- **URL** : `https://prometheus.mchegdali.cloud`
- **Métriques collectées** :
  - Système (Node Exporter)
  - Conteneurs (cAdvisor)
  - Applications (métriques custom)
  - Traefik (métriques intégrées)

#### Grafana
- **URL** : `https://grafana.mchegdali.cloud`
- **Dashboards inclus** :
  - Vue d'ensemble ASPHub
  - Métriques serveur ASPHub
  - Métriques système
  - Métriques Docker Swarm

#### AlertManager
- **URL** : `https://alertmanager.mchegdali.cloud`
- **Notifications** :
  - Alertes système
  - Alertes applicatives
  - Notifications sur Discord (possibilité d'ajouter d'autres moyens comme les emails, Slack, ...)

#### Uptime Kuma
- **URL** : `https://uptime.mchegdali.cloud`
- **Monitoring** :
  - Surveillance des services HTTP/HTTPS
  - Contrôle de l'état des API
  - Alertes en temps réel
  - Dashboard de statut public
  - Notifications intégrées
- **Monitors configurés** :
  - ASPHub Main (https://mchegdali.cloud)
  - ASPHub API (https://mchegdali.cloud/api/health)
  - Grafana (https://grafana.mchegdali.cloud)
  - Prometheus (https://prometheus.mchegdali.cloud)
  - AlertManager (https://alertmanager.mchegdali.cloud)
  - Traefik (https://traefik.mchegdali.cloud)

## 📊 Surveillance et monitoring

### Dashboards Grafana

1. **ASPHub Overview Dashboard**
   - Santé générale de l'application
   - Métriques de performance
   - État des services

2. **ASPHub Server Dashboard**
   - Métriques détaillées du backend
   - Performance API
   - Utilisation ressources

3. **Infrastructure Dashboard**
   - Santé des serveurs
   - Utilisation CPU/RAM/Disk
   - Métriques réseau

4. **ASPHub Backup Dashboard**
   - État des sauvegardes
   - Statistiques de sauvegarde
   - Alertes de sauvegarde

5. **Uptime Kuma Dashboard**
   - État des services d'Uptime Kuma
   - Métriques de performance
   - Utilisation des ressources

### Alertes configurées

- **Haute utilisation CPU** (>80% pendant 5min)
- **Mémoire faible** (<200MB disponible)
- **Espace disque faible** (<10% disponible)
- **Services indisponibles**
- **Certificats SSL expirant** (<30 jours)

### Accès aux logs

```bash
# Logs Traefik
docker service logs proxy_traefik

# Logs ASPHub
docker service logs asphub_server
docker service logs asphub_client

# Logs monitoring
docker service logs monitoring_prometheus
docker service logs monitoring_grafana

# Logs Uptime Kuma
docker service logs uptime-kuma_uptime-kuma
```

## 🌍 Gestion des environnements

### Structure des environnements

```
terraform/envs/
├── production/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── cloud-init.yaml.tftpl
└── staging/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── cloud-init.yaml
```

### Différences Production vs Staging

| Aspect | Production | Staging |
|--------|------------|---------|
| **Serveurs** | 3x cx22 (4GB RAM) | 3x cx22 (4GB RAM) |
| **Domaine** | mchegdali.cloud | staging.mchegdali.cloud |
| **SSL** | Let's Encrypt Prod | Let's Encrypt Staging |
| **Backups** | Quotidiens | Hebdomadaires |
| **Monitoring** | Complet | Allégé |

### Basculement entre environnements

```bash
# Déployer en staging
./deploy.sh --environment staging

# Tester et valider...

# Déployer en production
./deploy.sh --environment production
```

## 🔧 Maintenance

### Mises à jour

#### Mise à jour manuelle
```bash
# Mettre à jour une stack spécifique
./deploy.sh --environment production --tags asphub --skip-terraform

# Mise à jour complète
./deploy.sh --environment production
```

### Sauvegardes

#### Base de données PostgreSQL
```bash
# Backup manuel
docker exec $(docker ps -q -f name=asphub_postgres) \
  pg_dump -U postgres asphub > backup_$(date +%Y%m%d).sql

# Restauration
docker exec -i $(docker ps -q -f name=asphub_postgres) \
  psql -U postgres asphub < backup_20250715.sql
```

#### Volumes Docker
```bash
# Backup des volumes
docker run --rm -v asphub_postgres_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/postgres_backup_$(date +%Y%m%d).tar.gz -C /data .
```

### Scaling

#### Ajout de workers
```bash
# 1. Modifier terraform/envs/production/main.tf
# 2. Appliquer les changements
cd terraform/envs/production
terraform apply

# 3. Reconfigurer Ansible
cd ../../ansible
ansible-playbook -i inventory.yml playbooks/site.yml --tags swarm
```

#### Scaling des services
```bash
# Augmenter le nombre de répliques
docker service update --replicas 3 asphub_server
```

## 🚨 Troubleshooting

### Problèmes courants

#### 1. Échec de déploiement Terraform
```bash
# Vérifier les tokens
echo $HCLOUD_TOKEN

# Réinitialiser l'état
cd terraform/envs/production
terraform refresh
```

#### 2. Services inaccessibles
```bash
# Vérifier l'état des services
docker service ls
docker service ps <service_name>

# Vérifier les logs
docker service logs <service_name>
```

#### 3. Problèmes SSL
```bash
# Vérifier les certificats Let's Encrypt
docker exec <traefik_container> \
  cat /letsencrypt/acme.json | jq '.letsencrypt.Certificates'

# Forcer le renouvellement
docker service update --force proxy_traefik
```

#### 4. Problèmes de résolution DNS
```bash
# Vérifier la configuration DNS
dig mchegdali.cloud
nslookup grafana.mchegdali.cloud
```

### Commandes de diagnostic

```bash
# État du cluster Swarm
docker node ls
docker service ls
docker stack ls

# Utilisation des ressources
docker stats
docker system df

# Logs système
journalctl -u docker.service
```

### Rollback

#### Rollback de service
```bash
# Rollback automatique
docker service rollback <service_name>

# Rollback manuel vers une version spécifique
docker service update --image <image:version> <service_name>
```

#### Rollback infrastructure
```bash
# Restaurer un état Terraform précédent
cd terraform/envs/production
terraform state list
terraform show
terraform apply -target=<resource>
```

## 👥 Contribution

### Structure du projet

```
ASP-iac/
├── terraform/                 # Infrastructure as Code
│   └── envs/                 # Environnements (prod/staging)
├── ansible/                  # Configuration management
│   ├── playbooks/           # Playbooks principaux
│   │   └── roles/           # Rôles modulaires
│   └── inventory.yml        # Inventaire des serveurs
├── deploy.sh                # Script de déploiement principal
└── README.md               # Documentation
```

### Standards de code

#### Terraform
- Utiliser `terraform fmt`
- Valider avec `terraform validate`
- Commentaires pour les ressources complexes

#### Ansible
- Suivre les bonnes pratiques Ansible
- Utiliser `ansible-lint`
- Variables dans `group_vars/`

#### Scripts Bash
- Scripts avec `set -euo pipefail`
- Documentation des fonctions
- Gestion d'erreurs appropriée

### Tests

#### Tests d'infrastructure
```bash
# Validation Terraform
terraform validate
terraform plan

# Tests Ansible
ansible-playbook --syntax-check playbooks/site.yml
ansible-lint playbooks/
```

#### Tests de déploiement
```bash
# Test complet en staging
./deploy.sh --environment staging --verbose

# Dry run en production
./deploy.sh --environment production --dry-run
```

---

## 📚 Ressources additionnelles

- [Documentation Terraform](https://www.terraform.io/docs)
- [Documentation Ansible](https://docs.ansible.com/)
- [Docker Swarm Guide](https://docs.docker.com/engine/swarm/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Prometheus Documentation](https://prometheus.io/docs/)
