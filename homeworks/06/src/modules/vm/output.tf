output "cluster_id" {
  value = yandex_mdb_mysql_cluster.cluster.id
}

output "db_host" {
  value = yandex_mdb_mysql_cluster.cluster.host[0].fqdn
}

output "db_port" {
  value = 3306
}