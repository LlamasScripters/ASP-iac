variable "project_name" {
  type    = string
  default = "asphub"
}

variable "location" {
  type    = string
  default = "nbg1"
}

variable "server_type" {
  type    = string
  default = "cx22"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key to be added to the nodes"
  sensitive   = true
}
