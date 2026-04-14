# ======================================================================
# outputs.tf — Вывод результатов после terraform apply
# ======================================================================

output "vm_external_ip" {
  description = "Внешний IP-адрес ВМ (для доступа по SSH/HTTP)"
  value       = module.app_vm.external_ip
}

output "vm_internal_ip" {
  description = "Внутренний IP-адрес ВМ (для связи с MySQL)"
  value       = module.app_vm.internal_ip
}

output "mysql_connection_string" {
  description = "Строка подключения к MySQL (без пароля)"
  value       = "mysql://${var.mysql_user}@${module.mysql.db_host}:${module.mysql.db_port}/${var.mysql_db_name}"
  sensitive   = true
}

output "mysql_cluster_id" {
  description = "ID кластера Managed MySQL"
  value       = module.mysql.cluster_id
}

output "registry_url" {
  description = "URL Container Registry для docker push/pull"
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
  value       = var.use_lockbox ? var.lockbox_secret_id : null
}

# 💡 Полезная команда для проверки
output "health_check_command" {
  description = "Команда для проверки доступности приложения"
  value       = "curl -f http://${module.app_vm.external_ip}/ || echo 'Приложение недоступно'"
}