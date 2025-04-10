variable "hcloud_token" {
  sensitive = true
}

# variable "access_key" {}
# variable "secret_key" {}

variable "project_name" {
  type    = string
  default = "projetfinal"
}

variable "location" {
  type    = string
  default = "nbg1"
}

variable "server_type" {
  type    = string
  default = "cx22"
}
