terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.50.0"
    }
  }

  backend "remote" {
    organization = "moustaphachegdali"
    workspaces {
      name = "projetfinal"
    }
  }
}

locals {
  image = "ubuntu-24.04"
}

provider "hcloud" {
}

data "hcloud_ssh_key" "ssh_key" {
  name = "ssh-${var.project_name}-prod"
}

resource "hcloud_server" "manager" {
  name        = "srv-${var.project_name}-manager-prod"
  image       = local.image
  server_type = var.server_type
  location    = var.location
  labels = {
    "type" = "manager"
    "env"  = "prod"
  }

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  ssh_keys = [data.hcloud_ssh_key.ssh_key.id]

  lifecycle {
    ignore_changes = [ssh_keys]
  }

  user_data = file("cloud-init.yaml")
}

resource "hcloud_server" "worker1" {
  name        = "srv-${var.project_name}-worker1-prod"
  image       = local.image
  server_type = var.server_type
  location    = var.location

  labels = {
    "type" = "worker"
    "env"  = "prod"
  }

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  ssh_keys = [data.hcloud_ssh_key.ssh_key.id]

  lifecycle {
    ignore_changes = [ssh_keys]
  }

  user_data = file("cloud-init.yaml")
}

resource "hcloud_server" "worker2" {
  name        = "srv-${var.project_name}-worker2-prod"
  image       = local.image
  server_type = var.server_type
  location    = var.location

  labels = {
    "type" = "worker"
    "env"  = "prod"
  }

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  ssh_keys = [data.hcloud_ssh_key.ssh_key.id]

  lifecycle {
    ignore_changes = [ssh_keys]
  }

  user_data = file("cloud-init.yaml")
}

resource "hcloud_network" "network" {
  name     = "net-${var.project_name}"
  ip_range = "10.0.0.0/16"
  labels = {
    "env" = "prod"
  }
}

resource "hcloud_network_subnet" "subnet" {
  network_id   = hcloud_network.network.id
  type         = "cloud"
  network_zone = "eu-central"

  ip_range = "10.0.0.0/24"
}

resource "hcloud_server_network" "manager_network" {
  server_id  = hcloud_server.manager.id
  network_id = hcloud_network.network.id
  ip         = "10.0.0.10"
}

resource "hcloud_server_network" "worker1_network" {
  server_id  = hcloud_server.worker1.id
  network_id = hcloud_network.network.id
  ip         = "10.0.0.11"
}

resource "hcloud_server_network" "worker2_network" {
  server_id  = hcloud_server.worker2.id
  network_id = hcloud_network.network.id
  ip         = "10.0.0.12"
}
