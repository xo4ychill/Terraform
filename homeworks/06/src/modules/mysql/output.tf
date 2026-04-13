output "cluster_id" {
  description = "ID кластера MySQL"
  value       = yandex_mdb_mysql_cluster.cluster.id
}

output "db_host" {
  description = "Хост подключения к MySQL (FQDN)"
  value       = yandex_mdb_mysql_cluster.cluster.host[0].fqdn
}

output "db_port" {
  description = "Порт подключения к MySQL"
  value       = 3306
}

output "database_id" {
  description = "ID базы данных"
  value       = yandex_mdb_mysql_database.database.id
}
