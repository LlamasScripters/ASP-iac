terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.50.0"
    }

    ovh = {
      source  = "ovh/ovh"
      version = "2.4.0"
    }

    ansible = {
      source  = "ansible/ansible"
      version = "1.3.0"
    }
  }

  backend "remote" {
    organization = "moustaphachegdali"
    workspaces {
      name = "asphub-production"
    }
  }
}

locals {
  image = "ubuntu-24.04"
}

provider "hcloud" {
}

provider "ovh" {
}

resource "hcloud_ssh_key" "ssh_key" {
  name       = "ssh-${var.project_name}-prod"
  public_key = var.ssh_public_key
}

resource "hcloud_server" "manager" {
  name        = "srv-${var.project_name}-manager-prod"
  image       = local.image
  server_type = var.manager_server_type
  location    = var.location
  labels = {
    "type" = "manager"
    "env"  = "production"
  }

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  ssh_keys = [hcloud_ssh_key.ssh_key.id]

  lifecycle {
    ignore_changes = [ssh_keys]
  }

  user_data = templatefile("cloud-init.yaml.tftpl", {
    ssh_public_key = var.ssh_public_key
  })
}

resource "hcloud_server" "worker1" {
  name        = "srv-${var.project_name}-worker1-prod"
  image       = local.image
  server_type = var.worker_server_type
  location    = var.location

  labels = {
    "type" = "worker"
    "env"  = "production"
  }

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  ssh_keys = [hcloud_ssh_key.ssh_key.id]

  lifecycle {
    ignore_changes = [ssh_keys]
  }

  user_data = templatefile("cloud-init.yaml.tftpl", {
    ssh_public_key = var.ssh_public_key
  })
}

resource "hcloud_server" "worker2" {
  name        = "srv-${var.project_name}-worker2-prod"
  image       = local.image
  server_type = var.worker_server_type
  location    = var.location

  labels = {
    "type" = "worker"
    "env"  = "production"
  }

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  ssh_keys = [hcloud_ssh_key.ssh_key.id]

  lifecycle {
    ignore_changes = [ssh_keys]
  }

  user_data = templatefile("cloud-init.yaml.tftpl", {
    ssh_public_key = var.ssh_public_key
  })
}

resource "hcloud_server" "database" {
  name        = "srv-${var.project_name}-database-prod"
  image       = local.image
  server_type = var.database_server_type
  location    = var.location

  labels = {
    "type" = "database"
    "env"  = "production"
  }

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  ssh_keys = [hcloud_ssh_key.ssh_key.id]

  lifecycle {
    ignore_changes = [ssh_keys]
  }

  user_data = templatefile("cloud-init.yaml.tftpl", {
    ssh_public_key = var.ssh_public_key
  })
}

resource "hcloud_network" "network" {
  name     = "net-${var.project_name}-prod"
  ip_range = "192.168.0.0/16"
  labels = {
    "env" = "production"
  }
}

resource "hcloud_network_subnet" "subnet" {
  network_id   = hcloud_network.network.id
  type         = "cloud"
  network_zone = "eu-central"

  ip_range = "192.168.0.0/24"
}

resource "hcloud_server_network" "manager_network" {
  server_id  = hcloud_server.manager.id
  network_id = hcloud_network.network.id
  ip         = "192.168.0.100"
}

resource "hcloud_server_network" "worker1_network" {
  server_id  = hcloud_server.worker1.id
  network_id = hcloud_network.network.id
  ip         = "192.168.0.101"
}

resource "hcloud_server_network" "worker2_network" {
  server_id  = hcloud_server.worker2.id
  network_id = hcloud_network.network.id
  ip         = "192.168.0.102"
}

resource "hcloud_server_network" "database_network" {
  server_id  = hcloud_server.database.id
  network_id = hcloud_network.network.id
  ip         = "192.168.0.103"
}

#region DNS

data "ovh_domain_zone" "root_zone" {
  name = "mchegdali.cloud"
}

locals {
  domain     = data.ovh_domain_zone.root_zone.name
  subdomains = ["grafana", "traefik", "asphub", "prometheus", "alertmanager", "uptime"]
}

resource "ovh_domain_zone_record" "primary_dns" {
  zone      = local.domain
  subdomain = ""
  fieldtype = "A"
  target    = hcloud_server.manager.ipv4_address
}

resource "ovh_domain_zone_record" "subdomains" {
  zone      = local.domain
  for_each  = toset(local.subdomains)
  subdomain = each.value
  fieldtype = "CNAME"
  ttl       = 3600
  target    = "${local.domain}."

  depends_on = [ovh_domain_zone_record.primary_dns]
}

#endregion DNS

#region Ansible

resource "ansible_group" "managers" {
  name = "managers"

  variables = {
    domain = local.domain
  }
}

resource "ansible_group" "workers" {
  name = "workers"
}

resource "ansible_group" "database" {
  name = "database"

  variables = {
    domain = local.domain
  }
}

resource "ansible_host" "manager" {
  name   = hcloud_server.manager.name
  groups = ["managers"]

  variables = {
    ansible_user = "asphub"
    ansible_host = hcloud_server.manager.ipv4_address
  }

  depends_on = [ansible_group.managers, hcloud_server.manager]
}

resource "ansible_host" "worker1" {
  name   = hcloud_server.worker1.name
  groups = ["workers"]

  variables = {
    ansible_user = "asphub"
    ansible_host = hcloud_server.worker1.ipv4_address
  }

  depends_on = [ansible_group.workers, hcloud_server.worker1]
}

resource "ansible_host" "worker2" {
  name   = hcloud_server.worker2.name
  groups = ["workers"]

  variables = {
    ansible_user = "asphub"
    ansible_host = hcloud_server.worker2.ipv4_address
  }

  depends_on = [ansible_group.workers, hcloud_server.worker2]
}

resource "ansible_host" "database" {
  name   = hcloud_server.database.name
  groups = ["database"]

  variables = {
    ansible_user = "asphub"
    ansible_host = hcloud_server.database.ipv4_address
  }

  depends_on = [ansible_group.database, hcloud_server.database]
}
