terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.50.0"
    }

    minio = {
      source  = "aminueza/minio"
      version = "3.3.0"
    }
  }

  backend "s3" {
    bucket = "projetfinal-tfstate"

    endpoints = {
      s3 = "https://nbg1.your-objectstorage.com"
    }

    access_key = ""
    secret_key = ""

    key                         = "terraform.tfstate"
    region                      = "nbg1"
    skip_requesting_account_id  = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    use_path_style              = true
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

variable "access_key" {}
variable "secret_key" {}

provider "minio" {
  minio_server   = "nbg1.your-objectstorage.com"
  minio_user     = var.access_key
  minio_password = var.secret_key
  minio_region   = "nbg1"
  minio_ssl      = true
}

resource "random_uuid" "id" {}

resource "minio_s3_bucket" "bucket" {
  bucket         = random_uuid.id.result
  acl            = "private"
  object_locking = false
}

resource "hcloud_ssh_key" "ssh_key" {
  name       = "ssh-${var.project_name}"
  public_key = file("~/.ssh/hetzner.pub")
}

resource "hcloud_server" "manager" {
  name        = "srv-${var.project_name}-manager"
  image       = "debian-12"
  server_type = var.server_type
  location    = var.location

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  ssh_keys = [hcloud_ssh_key.ssh_key.id]
}

resource "hcloud_server" "worker1" {
  name        = "srv-${var.project_name}-worker1"
  image       = "debian-12"
  server_type = var.server_type
  location    = var.location

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  ssh_keys = [hcloud_ssh_key.ssh_key.id]
}

resource "hcloud_server" "worker2" {
  name        = "srv-${var.project_name}-worker2"
  image       = "debian-12"
  server_type = var.server_type
  location    = var.location

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  ssh_keys = [hcloud_ssh_key.ssh_key.id]

}


resource "hcloud_network" "network" {
  name     = "net-${var.project_name}"
  ip_range = "10.0.0.0/16"
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
