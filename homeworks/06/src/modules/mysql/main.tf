# ======================================================================
# Модуль MySQL — Yandex Managed Service for MySQL
# Создание кластера MySQL, базы данных и пользователя
# ======================================================================

# --- Кластер MySQL ---
resource "yandex_mdb_mysql_cluster" "cluster" {
  name                = "${var.environment}-mysql-cluster"
  environment         = var.environment
  network_id          = var.network_id
  version             = var.mysql_version

  # Конфигурация ресурсов кластера
  resources {
    resource_preset_id = "s2.micro"   # 2 vCPU, 8 GB RAM (минимальный для MySQL 8.0)
    disk_type_id       = "network-hdd"
    disk_size          = 20
  }

  # Настройки MySQL
  mysql_config {
    innodb_buffer_pool_size = 1073741824  # 1 GB
    max_connections         = 100
    sql_mode                = "STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION"
  }

  # Настройки резервного копирования
  backup_window_start {
    hours   = 3   # Начало окна бэкапа — 03:00 UTC
    minutes = 0
  }

  # Настройки обслуживания
  maintenance_window {
    type = "ANYTIME"
  }

  # Хост в подсети (одна зона доступности)
  host {
    zone_id      = var.zone
    subnet_id    = var.subnet_id
    assign_public_ip = false  # MySQL не должен иметь публичный IP
  }

  security_group_ids = var.security_group_ids

  labels = {
    environment = var.environment
  }
  
  lifecycle {
    prevent_destroy = true
  }
}

# --- База данных ---
resource "yandex_mdb_mysql_database" "database" {
  cluster_id = yandex_mdb_mysql_cluster.cluster.id
  name       = var.db_name
  charset    = "utf8mb4"
  collation  = "utf8mb4_unicode_ci"
}

# --- Пользователь базы данных ---
resource "yandex_mdb_mysql_user" "user" {
  cluster_id = yandex_mdb_mysql_cluster.cluster.id
  name       = var.db_user
  password   = var.db_password

  permission {
    database_name = var.db_name
    roles         = ["ALL"]
  }

  # Глобальные привилегии
  global_permissions = ["PROCESS", "REPLICATION_CLIENT"]

  connection_limits {
    max_questions_per_hour   = 0
    max_updates_per_hour     = 0
    max_connections_per_hour = 0
    max_user_connections     = 10
  }
}
