# ==================== OUTPUTS ====================
# Вывод значений после terraform apply

output "vm_external_ip" {
  description = "Внешний IP-адрес ВМ с приложением"
  value       = module.app_vm.external_ip
}

output "vm_internal_ip" {
  description = "Внутренний IP-адрес ВМ"
  value       = module.app_vm.internal_ip
}

output "mysql_cluster_id" {
  description = "ID кластера MySQL"
  value       = module.mysql.cluster_id
}

output "mysql_db_host" {
  description = "Хост подключения к MySQL"
  value       = module.mysql.db_host
  sensitive   = true
}

output "mysql_db_port" {
  description = "Порт подключения к MySQL"
  value       = module.mysql.db_port
}

output "registry_url" {
  description = "URL Container Registry"
  value       = yandex_container_registry.app_registry.url
}

output "registry_id" {
  description = "ID Container Registry"
  value       = yandex_container_registry.app_registry.id
}

output "security_group_id" {
  description = "ID группы безопасности"
  value       = yandex_vpc_security_group.app_sg.id
}

output "network_id" {
  description = "ID сети VPC"
  value       = module.vpc.network_id
}

output "subnet_id" {
  description = "ID подсети"
  value       = module.vpc.subnet_id
}

output "lockbox_secret_id" {
  description = "ID секрета в LockBox (если используется)"
  value       = try(yandex_lockbox_secret.mysql_secret[0].id, null)
}
