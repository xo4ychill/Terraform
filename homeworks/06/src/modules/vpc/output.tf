output "network_id" {
  description = "ID сети"
  value       = yandex_vpc_network.network.id
}

output "subnet_id" {
  description = "ID подсети"
  value       = yandex_vpc_subnet.subnet.id
}