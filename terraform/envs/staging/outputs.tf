output "manager_ip" {
  value = hcloud_server.manager.ipv4_address
}

output "workers_ips" {
  value = hcloud_server.workers[*].ipv4_address
}

output "workers_names" {
  value = hcloud_server.workers[*].name
}

output "workers_private_ips" {
  value = hcloud_server_network.workers_network[*].ip
}
