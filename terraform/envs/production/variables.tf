variable "project_name" {
  type    = string
  default = "asphub"
}

variable "location" {
  type    = string
  default = "nbg1"
}

variable "manager_server_type" {
  type        = string
  default     = "cx32"
  description = "Manager server type"
}

variable "worker_server_type" {
  type        = string
  default     = "cx22"
  description = "Worker server type"
}

variable "database_server_type" {
  type        = string
  default     = "cx22"
  description = "Dedicated database server type - use cx22 for now, cx32 is optimal but too expensive for now"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key to be added to the nodes"
  sensitive   = true
}
