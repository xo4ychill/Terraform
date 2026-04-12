output "subnet_id" {
  description = "ID созданной подсети"
  value       = yandex_vpc_subnet.develop.id
}

output "network_id" {
  description = "ID созданной сети"
  value       = yandex_vpc_network.develop.id
}

output "subnet_name" {
  description = "Имя подсети"
  value       = yandex_vpc_subnet.develop.name
}

output "network_name" {
  description = "Имя сети"
  value       = yandex_vpc_network.develop.name
}

output "subnet_zone" {
  description = "Зона доступности подсети"
  value       = yandex_vpc_subnet.develop.zone
}

output "subnet_cidr_blocks" {
  description = "CIDR блоки подсети"
  value       = yandex_vpc_subnet.develop.v4_cidr_blocks
}