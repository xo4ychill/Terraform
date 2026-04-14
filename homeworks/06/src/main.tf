# ======================================================================
# ИТОГОВЫЙ ПРОЕКТ — РАЗВЁРТЫВАНИЕ ИНФРАСТРУКТУРЫ В YANDEX CLOUD
# Terraform + Docker + MySQL + Container Registry + LockBox
# ======================================================================
# ==================== VPC: СЕТЬ И ПОДСЕТЬ ====================
# Модуль создаёт облачную сеть и подсеть без хардкода
module "vpc" {
  source = "./modules/vpc"
  network_name   = var.vpc_name
  subnet_name    = var.subnet_name
  zone           = var.default_zone
  v4_cidr_blocks = var.v4_cidr_blocks
}
# ==================== GROUP SECURITY ====================
# Группа безопасности: порты 22 (SSH), 80 (HTTP), 443 (HTTPS)
resource "yandex_vpc_security_group" "app_sg" {
  name        = "${var.vpc_name}-sg"
  description = "Security group for application VM"
  network_id  = module.vpc.network_id
  # ----- Входящие правила (Ingress) -----
  # SSH-доступ (порт 22) — только с разрешённого CIDR
  ingress {
    description    = "SSH access"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = [var.allowed_ssh_cidr]
  }
  # HTTP-доступ (порт 80) — для всех
  ingress {
    description    = "HTTP access"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  # HTTPS-доступ (порт 443) — для всех
  ingress {
    description    = "HTTPS access"
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  # ----- Исходящие правила (Egress) -----
  # Разрешаем весь исходящий трафик
  egress {
    description    = "Allow all outbound traffic"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  labels = {
    environment = var.environment
  }
}
# ==================== CONTAINER REGISTRY ====================
# Создаём реестр Docker-образов в Yandex Cloud
resource "yandex_container_registry" "app_registry" {
  name = var.registry_name
  labels = {
    environment = var.environment
  }
}
# ==================== MYSQL — Managed Database ====================
# Создаём кластер MySQL через модуль
module "mysql" {
  source = "./modules/mysql"
  network_id     = module.vpc.network_id
  subnet_id      = module.vpc.subnet_id
  zone           = var.default_zone
  mysql_version  = var.mysql_version
  db_name        = var.mysql_db_name
  db_user        = var.mysql_user
  # Пароль: из переменной или из LockBox
  db_password = var.use_lockbox ? data.yandex_lockbox_secret_version.mysql_password.payload["password"] : var.mysql_password
  environment = var.environment
}
# ==================== LOCKBOX: СЕКРЕТЫ ====================
# (Только если включён флаг use_lockbox)
# Данные считываются из уже существующего секрета в LockBox
data "yandex_lockbox_secret_version" "mysql_password" {
  count = var.use_lockbox ? 1 : 0
  secret_id = yandex_lockbox_secret.mysql_secret[0].id
}
# Создание секрета в LockBox (если use_lockbox = true)
resource "yandex_lockbox_secret" "mysql_secret" {
  count = var.use_lockbox ? 1 : 0
  name        = var.lockbox_secret_name
  description = "MySQL credentials for ${var.environment}"
  folder_id   = var.folder_id
  # Добавляем пароль в секрет
  # Пароль берём из переменной при первом создании
  # После создания секрет управляется через консоль или CLI
}
resource "yandex_lockbox_secret_version" "mysql_secret_version" {
  count = var.use_lockbox ? 1 : 0
  secret_id = yandex_lockbox_secret.mysql_secret[0].id
  # При создании записываем пароль из переменной
  entries {
    key   = "password"
    text_value = var.mysql_password
  }
}
# ==================== CLOUD-INIT ====================
# Генерация cloud-init конфигурации для ВМ
# Установка Docker и Docker Compose через cloud-init
locals {
  ssh_key_content   = var.ssh_public_key
  cloud_init_content = templatefile("${path.module}/cloud-init.yml.tpl", {
    ssh_key         = local.ssh_key_content
    registry_id     = yandex_container_registry.app_registry.id
    registry_url    = yandex_container_registry.app_registry.url
    db_host         = module.mysql.db_host
    db_port         = module.mysql.db_port
    db_name         = var.mysql_db_name
    db_user         = var.mysql_user
    db_password     = var.use_lockbox ? data.yandex_lockbox_secret_version.mysql_password[0].payload["password"] : var.mysql_password
  })
}
# ==================== ВИРТУАЛЬНАЯ МАШИНА ====================
# Создаём ВМ через модуль с привязкой:
#   - Security Group
#   - Cloud-init (Docker + Docker Compose)
#   - Container Registry (для pull образа)
module "app_vm" {
  source = "./modules/vm"
  vm_name            = var.vm_name
  project_label      = "app"
  subnet_id          = module.vpc.subnet_id
  cloud_init_content = local.cloud_init_content
  zone               = var.default_zone
  image_family       = var.image_family
  ssh_public_key     = local.ssh_key_content
  preemptible        = true
  security_group_ids = [yandex_vpc_security_group.app_sg.id]
  vm_cores           = var.vm_cores
  vm_memory          = var.vm_memory
  vm_disk_size       = var.vm_disk_size
}
