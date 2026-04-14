# ======================================================================
# main.tf — Основная инфраструктура: VPC, VM, MySQL, Registry, Security
# ======================================================================

# ==================== VPC: СЕТЬ И ПОДСЕТЬ ====================
module "vpc" {
  source = "./modules/vpc"
  
  network_name   = var.vpc_name
  subnet_name    = var.subnet_name
  zone           = var.default_zone
  v4_cidr_blocks = var.v4_cidr_blocks
  
  # Передаём метки для тегирования ресурсов
  environment = var.environment
}

# ==================== SECURITY GROUP ====================
resource "yandex_vpc_security_group" "app_sg" {
  name        = "${var.vpc_name}-sg"
  description = "Security group для приложения: SSH, HTTP, HTTPS, MySQL"
  network_id  = module.vpc.network_id
  
  # ----- Входящие правила (Ingress) -----
  
  # SSH: только с доверенных адресов
  ingress {
    description    = "SSH access"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = [var.allowed_ssh_cidr]
  }
  
  # HTTP: публичный доступ
  ingress {
    description    = "HTTP access"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  
  # HTTPS: публичный доступ
  ingress {
    description    = "HTTPS access"
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  
  # MySQL: только из подсети приложения (защита от внешнего доступа)
  ingress {
    description    = "MySQL from app subnet"
    protocol       = "TCP"
    port           = 3306
    v4_cidr_blocks = var.v4_cidr_blocks
  }
  
  # ----- Исходящие правила (Egress) -----
  # Разрешаем только необходимый трафик
  egress {
    description    = "HTTPS outbound"
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description    = "HTTP outbound"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description    = "DNS outbound"
    protocol       = "UDP"
    port           = 53
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  
  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
  
}

# ==================== CONTAINER REGISTRY ====================
resource "yandex_container_registry" "app_registry" {
  name = var.registry_name
  
  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
  
}

# ==================== LOCKBOX: ЧТЕНИЕ СЕКРЕТА ====================
# Читаем пароль из существующего секрета (не создаём через Terraform!)
data "yandex_lockbox_secret_version" "mysql_password" {
  count = var.use_lockbox ? 1 : 0
  secret_id = var.lockbox_secret_id
}

# ==================== MANAGED MYSQL ====================
module "mysql" {
  source = "./modules/mysql"
  
  network_id    = module.vpc.network_id
  subnet_id     = module.vpc.subnet_id
  zone          = var.default_zone
  environment   = var.environment
  
  mysql_version = var.mysql_version
  db_name       = var.mysql_db_name
  db_user       = var.mysql_user
  
  # ✅ Пароль: из LockBox (приоритет) или из переменной
  db_password = var.use_lockbox && var.lockbox_secret_id != "" ? (
    data.yandex_lockbox_secret_version.mysql_password[0].payload["password"]
  ) : var.mysql_password
  
  # Передаём правила безопасности для автоматической привязки
  security_group_ids = [yandex_vpc_security_group.app_sg.id]
}

# ==================== CLOUD-INIT: ШАБЛОН КОНФИГУРАЦИИ ====================
locals {
  # Не передаём пароль напрямую в cloud-init
  cloud_init_content = templatefile("${path.module}/cloud-init.yml.tpl", {
    ssh_key         = var.ssh_public_key
    registry_id     = yandex_container_registry.app_registry.id
    registry_url    = yandex_container_registry.app_registry.url
    db_host         = module.mysql.db_host
    db_port         = module.mysql.db_port
    db_name         = var.mysql_db_name
    db_user         = var.mysql_user
    # Передаём только ссылку на секрет, а не сам пароль
    lockbox_secret_id = var.use_lockbox ? var.lockbox_secret_id : ""
    use_lockbox     = var.use_lockbox
    environment     = var.environment
  })
}

# ==================== ВИРТУАЛЬНАЯ МАШИНА ====================
module "app_vm" {
  source = "./modules/vm"
  
  vm_name            = var.vm_name
  project_label      = "app"
  environment_label  = var.environment
  
  subnet_id          = module.vpc.subnet_id
  security_group_ids = [yandex_vpc_security_group.app_sg.id]
  
  cloud_init_content = local.cloud_init_content
  zone               = var.default_zone
  image_family       = var.image_family
  ssh_public_key     = var.ssh_public_key
  
  vm_cores           = var.vm_cores
  vm_memory          = var.vm_memory
  vm_disk_size       = var.vm_disk_size
  
  # Прерываемая ВМ для экономии (не для critical prod!)
  preemptible = var.environment != "prod"
  

}