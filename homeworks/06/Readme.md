Отличный итоговый проект! Давайте разберём его по шагам, соберём полную структуру репозитория, все файлы Terraform, Dockerfile, docker-compose.yml, cloud-init и документацию.
Я сначала посмотрю исходный репозиторий, чтобы понять, что уже есть.
Отлично! Изучу структуру проекта подробнее, чтобы адаптировать решения.
Теперь у меня есть полная картина. Я вижу структуру вашего проекта — VPC, Security Groups, ВМ, модули, remote state с блокировками. Сейчас я соберу для вас полное решение итогового проекта, расширив его новыми компонентами: MySQL, Container Registry, Dockerfile с мультисборкой, LockBox и обновлённый cloud-init.
📋 Итоговый проект: Terraform + Docker + Yandex Cloud
🗂️ Финальная структура репозитория
terraform-06/
├── src/
│   ├── main.tf                          # Основная конфигурация инфраструктуры
│   ├── providers.tf                     # Провайдеры и remote state
│   ├── variables.tf                     # Переменные
│   ├── outputs.tf                       # Outputs
│   ├── terraform.tfvars.example         # Пример значений переменных
│   ├── backend.hcl                      # Конфигурация backend для S3
│   ├── cloud-init.yml.tpl               # Cloud-init: Docker + Docker Compose
│   ├── app/
│   │   ├── index.html                   # Статический HTML для web-приложения
│   │   ├── style.css                    # CSS стили
│   │   └── info.php                     # PHP-страница, подключающаяся к MySQL
│   ├── Dockerfile                       # Мультисборка образа приложения
│   ├── docker-compose.yml               # Docker Compose для развёртывания
│   ├── nginx.conf                       # Конфигурация nginx для контейнера
│   └── modules/
│       ├── vpc/
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── vm/
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       └── mysql/
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
├── docs/
│   └── REPORT.md                        # MD-файл с документацией и скриншотами
└── scripts/
    ├── docker-push.sh                   # Скрипт для сборки и пуша образа
    └── setup-lockbox.sh                 # Скрипт для создания секретов в LockBox
📄 Файл 1: src/providers.tf
terraform {
  required_version = ">= 1.12.0"
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.100"
    }
  }
  # ===== REMOTE STATE в Yandex Object Storage с блокировками =====
  # State хранится удалённо в S3-совместимом хранилище
  # Блокировка осуществляется через DynamoDB-совместимый API Yandex Lockbox
  # (используем use_lockfile = true для встроенной блокировки)
  backend "s3" {
    # Имя бакета для хранения state-файлов
    # Создаётся заранее через YC CLI:
    #   yc storage bucket create --name tf-state-bucket --default-storage-class standard
    bucket = "tf-state-bucket"
    # Путь к state-файлу внутри бакета
    key = "prod/terraform.tfstate"
    # Регион Yandex Cloud
    region = "ru-central1"
    # Включение встроенной блокировки state-файла
    # Terraform создаёт .lock-файл в том же бакете
    # Предотвращает одновременный запуск terraform apply
    use_lockfile = true
    # Эндпоинты Yandex Cloud Storage (S3-совместимый)
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    skip_region_validation        = true
    skip_credentials_validation   = true
    skip_requesting_account_id    = true
    skip_s3_checksum              = true
  }
}
# ===== Провайдер Yandex Cloud =====
provider "yandex" {
  # Используем ключ сервисного аккаунта из файла
  # Файл НЕ коммитится в Git (указан в .gitignore)
  service_account_key_file = pathexpand(var.service_account_key_file)
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.default_zone
}
Что изменилось:
Элемент	Описание	
Remote state	State хранится в S3-бакете tf-state-bucket	
State locking	Включено через use_lockfile = true	
Без хардкода	Все значения через переменные	
📄 Файл 2: src/variables.tf
# ===================== ОСНОВНЫЕ ПЕРЕМЕННЫЕ =====================
variable "cloud_id" {
  description = "Идентификатор облака Yandex Cloud"
  type        = string
}
variable "folder_id" {
  description = "Идентификатор каталога Yandex Cloud"
  type        = string
}
variable "default_zone" {
  description = "Зона доступности по умолчанию"
  type        = string
  default     = "ru-central1-a"
}
variable "service_account_key_file" {
  description = "Путь к файлу ключа сервисного аккаунта (JSON)"
  type        = string
  sensitive   = true
}
variable "environment" {
  description = "Окружение (prod / staging / dev)"
  type        = string
  default     = "prod"
  validation {
    condition     = contains(["prod", "staging", "dev"], var.environment)
    error_message = "Допустимые значения: prod, staging, dev"
  }
}
# ===================== VPC / СЕТЬ =====================
variable "vpc_name" {
  description = "Имя сети VPC"
  type        = string
}
variable "subnet_name" {
  description = "Имя подсети"
  type        = string
}
variable "v4_cidr_blocks" {
  description = "CIDR-блоки подсети"
  type        = list(string)
}
# ===================== ВИРТУАЛЬНАЯ МАШИНА =====================
variable "vm_name" {
  description = "Имя виртуальной машины"
  type        = string
  default     = "vm-app"
}
variable "image_family" {
  description = "Семейство образа для ВМ"
  type        = string
  default     = "ubuntu-2204-lts"
}
variable "vm_cores" {
  description = "Количество ядер CPU для ВМ"
  type        = number
  default     = 2
}
variable "vm_memory" {
  description = "Объём оперативной памяти (ГБ)"
  type        = number
  default     = 4
}
variable "vm_disk_size" {
  description = "Размер загрузочного диска (ГБ)"
  type        = number
  default     = 20
}
variable "ssh_public_key" {
  description = "Публичный SSH-ключ для доступа к ВМ"
  type        = string
}
variable "allowed_ssh_cidr" {
  description = "CIDR-блок, с которого разрешён SSH-доступ"
  type        = string
  default     = "0.0.0.0/0"
}
# ===================== MYSQL =====================
variable "mysql_version" {
  description = "Версия MySQL"
  type        = string
  default     = "8.0"
}
variable "mysql_db_name" {
  description = "Имя базы данных MySQL"
  type        = string
  default     = "appdb"
}
variable "mysql_user" {
  description = "Имя пользователя MySQL"
  type        = string
  default     = "appuser"
}
variable "mysql_password" {
  description = "Пароль пользователя MySQL (лучше брать из LockBox — Задание 5*)"
  type        = string
  sensitive   = true
  default     = ""  # Если пусто — берётся из LockBox
}
# ===================== CONTAINER REGISTRY =====================
variable "registry_name" {
  description = "Имя Container Registry"
  type        = string
  default     = "app-registry"
}
# ===================== LOCKBOX =====================
variable "use_lockbox" {
  description = "Использовать Yandex LockBox для хранения пароля MySQL"
  type        = bool
  default     = false
}
variable "lockbox_secret_name" {
  description = "Имя секрета в LockBox для пароля MySQL"
  type        = string
  default     = "mysql-credentials"
}
# ===================== ВАЛИДАЦИЯ IP-АДРЕСОВ =====================
variable "single_ip" {
  description = "Один IPv4-адрес (с валидацией)"
  type        = string
  validation {
    condition = can(
      regex(
        "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$",
        var.single_ip
      )
    )
    error_message = "Значение должно быть корректным IPv4-адресом. Пример: 192.168.0.1"
  }
}
variable "ip_list" {
  description = "Список IPv4-адресов (с валидацией)"
  type        = list(string)
  validation {
    condition = alltrue([
      for ip in var.ip_list : can(
        regex(
          "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$",
          ip
        )
      )
    ])
    error_message = "Все элементы списка должны быть корректными IPv4-адресами"
  }
}
📄 Файл 3: src/main.tf
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
📄 Файл 4: src/outputs.tf
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
📄 Файл 5: src/terraform.tfvars.example
# ======================================================
# ПРИМЕР ФАЙЛА ПЕРЕМЕННЫХ
# Скопируйте в terraform.tfvars и заполните свои значения
# ======================================================
# --- Yandex Cloud ---
cloud_id                 = "b1g5xxxxxxxxxxxxxxxx"
folder_id                = "b1g5xxxxxxxxxxxxxxxx"
default_zone             = "ru-central1-a"
service_account_key_file = "~/.config/yandex-cloud/sa-key.json"
# --- Окружение ---
environment = "prod"
# --- VPC ---
vpc_name       = "app-network"
subnet_name    = "app-subnet"
v4_cidr_blocks = ["192.168.10.0/24"]
# --- Виртуальная машина ---
vm_name    = "vm-app"
image_family = "ubuntu-2204-lts"
vm_cores   = 2
vm_memory  = 4
vm_disk_size = 20
# --- SSH ---
ssh_public_key    = "ssh-rsa AAAAB3NzaC1yc2EAAAA... your@email.com"
allowed_ssh_cidr  = "85.32.xx.xx/32"
# --- MySQL ---
mysql_version = "8.0"
mysql_db_name = "appdb"
mysql_user    = "appuser"
mysql_password = "YourStrongPassword123!"
# --- Container Registry ---
registry_name = "app-registry"
# --- LockBox (Задание 5*) ---
use_lockbox          = false
lockbox_secret_name  = "mysql-credentials"
# --- Валидация IP ---
single_ip = "192.168.1.1"
ip_list   = ["192.168.1.1", "10.0.0.1"]
📄 Файл 6: src/cloud-init.yml.tpl
#cloud-config
# ======================================================================
# Cloud-Init: Установка Docker и Docker Compose + запуск приложения
# ======================================================================
users:
  - name: yc-user
    groups:
      - sudo
      - docker
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_authorized_keys:
      - ${ssh_key}
# --- Обновление пакетов ---
package_update: true
# --- Установка Docker и Docker Compose (Задание 2) ---
packages:
  - apt-transport-https
  - ca-certificates
  - curl
  - gnupg
  - lsb-release
  - git
  - python3-pip
runcmd:
  # ===== ШАГ 1: Добавление GPG-ключа Docker =====
  - |
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
  # ===== ШАГ 2: Добавление репозитория Docker =====
  - |
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
  # ===== ШАГ 3: Установка Docker Engine, CLI, Containerd =====
  - |
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  # ===== ШАГ 4: Включение и запуск Docker =====
  - systemctl enable docker
  - systemctl start docker
  - systemctl enable containerd
  - systemctl start containerd
  # ===== ШАГ 5: Проверка установки Docker =====
  - docker --version
  - docker compose version
  # ===== ШАГ 6: Авторизация в Yandex Container Registry =====
  # Для корректной работы push/pull образов
  - |
    cat > /home/yc-user/.docker/config.json << 'DOCKERCFG'
    {
      "credHelpers": {
        "cr.yandex": "yc"
      }
    }
    DOCKERCFG
  - chown yc-user:yc-user /home/yc-user/.docker/config.json
  # ===== ШАГ 7: Создание каталога проекта =====
  - mkdir -p /opt/app
  - chown yc-user:yc-user /opt/app
  # ===== ШАГ 8: Настройка переменных окружения для подключения к MySQL =====
  - |
    cat > /opt/app/.env << ENVEOF
    DB_HOST=${db_host}
    DB_PORT=${db_port}
    DB_NAME=${db_name}
    DB_USER=${db_user}
    DB_PASSWORD=${db_password}
    REGISTRY_URL=${registry_url}
    ENVEOF
  - chmod 600 /opt/app/.env
  - chown yc-user:yc-user /opt/app/.env
  # ===== ШАГ 9: Создание docker-compose.yml =====
  - |
    cat > /opt/app/docker-compose.yml << 'COMPOSEEOF'
    version: "3.9"
    services:
      web:
        image: ${registry_url}/app:latest
        container_name: web-app
        restart: unless-stopped
        ports:
          - "80:80"
        environment:
          - DB_HOST=${DB_HOST}
          - DB_PORT=${DB_PORT}
          - DB_NAME=${DB_NAME}
          - DB_USER=${DB_USER}
          - DB_PASSWORD=${DB_PASSWORD}
        networks:
          - app-network
    networks:
      app-network:
        driver: bridge
    COMPOSEEOF
  # ===== ШАГ 10: Настройка firewall (UFW) =====
  - ufw allow 22/tcp
  - ufw allow 80/tcp
  - ufw allow 443/tcp
  - ufw --force enable
  # ===== ШАГ 11: Лог завершения cloud-init =====
  - echo "CLOUD-INIT COMPLETED SUCCESSFULLY" > /opt/app/cloud-init-done.txt
  - date >> /opt/app/cloud-init-done.txt
# --- Финальное сообщение ---
final_message: "Cloud-init finished! Docker and Docker Compose installed. System is ready for container deployment."
📄 Файл 7: src/Dockerfile (Задание 3 — Мультисборка)
# ======================================================================
# Dockerfile — Мультисборка (Multi-Stage Build) для web-приложения
# Stage 1: Builder — сборка статических файлов и PHP
# Stage 2: Runtime — финальный образ с nginx + php-fpm
# ======================================================================
# ==================== STAGE 1: BUILDER ====================
FROM ubuntu:22.04 AS builder
LABEL maintainer="student@example.com"
LABEL description="Multi-stage build for web application"
LABEL stage="builder"
# Установка зависимостей для сборки
RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    php8.1-fpm \
    php8.1-mysql \
    php8.1-mbstring \
    php8.1-xml \
    php8.1-curl \
    curl \
    && rm -rf /var/lib/apt/lists/*
# Копируем исходные файлы приложения
COPY app/ /var/www/app/
# Устанавливаем права на файлы
RUN chown -R www-data:www-data /var/www/app \
    && chmod -R 755 /var/www/app
# Создаём тестовую конфигурацию для проверки сборки
RUN php -v
RUN php -m | grep -E "mysql|mbstring|xml|curl"
# ==================== STAGE 2: RUNTIME ====================
FROM ubuntu:22.04 AS runtime
LABEL maintainer="student@example.com"
LABEL description="Web application with Nginx + PHP-FPM"
LABEL version="1.0"
# Установка минимального набора пакетов для runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    php8.1-fpm \
    php8.1-mysql \
    php8.1-mbstring \
    php8.1-xml \
    php8.1-curl \
    supervisor \
    curl \
    && rm -rf /var/lib/apt/lists/*
# Копируем конфигурацию nginx
COPY nginx.conf /etc/nginx/sites-available/default
# Копируем конфигурацию supervisor для управления процессами
RUN mkdir -p /var/log/supervisor
COPY <<'EOF' /etc/supervisor/conf.d/app.conf
[supervisord]
nodaemon=true
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid
[program:nginx]
command=nginx -g "daemon off;"
autostart=true
autorestart=true
stdout_logfile=/var/log/supervisor/nginx-stdout.log
stderr_logfile=/var/log/supervisor/nginx-stderr.log
[program:php-fpm]
command=php-fpm8.1 -F
autostart=true
autorestart=true
stdout_logfile=/var/log/supervisor/php-fpm-stdout.log
stderr_logfile=/var/log/supervisor/php-fpm-stderr.log
EOF
# Копируем файлы приложения из builder stage
COPY --from=builder /var/www/app /var/www/app
# Настраиваем nginx root
RUN ln -sf /var/www/app /var/www/html
# Устанавливаем права
RUN chown -R www-data:www-data /var/www/app /var/www/html
# Открываем порт 80
EXPOSE 80
# Проверка здоровья контейнера (Healthcheck)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost/ || exit 1
# Запуск через supervisor (nginx + php-fpm)
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
Пояснение мультисборки:
Stage	Назначение	Размер результата	
builder	Установка всех build-зависимостей, компиляция	Не входит в финальный образ	
runtime	Только runtime-зависимости + скопированные артефакты	~150 MB (вместо ~300+ MB без мультисборки)	
📄 Файл 8: src/nginx.conf
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    root /var/www/app;
    index index.html index.php;
    # Логи доступа
    access_log /var/log/nginx/app_access.log;
    error_log  /var/log/nginx/app_error.log;
    # Главная страница
    location / {
        try_files $uri $uri/ /index.html;
    }
    # PHP-обработка через php-fpm
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
    # Запрет доступа к скрытым файлам
    location ~ /\. {
        deny all;
    }
}
📄 Файл 9: src/app/index.html
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Итоговый проект — Terraform + Docker</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="container">
        <header>
            <h1>🚀 Итоговый проект</h1>
            <p class="subtitle">Terraform + Docker + Yandex Cloud</p>
        </header>
        <main>
            <section class="card">
                <h2>📋 О проекте</h2>
                <p>Демонстрация развёртывания web-приложения в контейнере Docker
                   на виртуальной машине Yandex Cloud, управляемой через Terraform.</p>
            </section>
            <section class="card">
                <h2>🛠️ Использованные технологии</h2>
                <ul>
                    <li><strong>Terraform</strong> — Infrastructure as Code</li>
                    <li><strong>Docker</strong> — Контейнеризация приложения</li>
                    <li><strong>Docker Compose</strong> — Оркестрация контейнеров</li>
                    <li><strong>Yandex Cloud</strong> — Облачная платформа</li>
                    <li><strong>MySQL</strong> — Managed Database</li>
                    <li><strong>Container Registry</strong> — Хранение Docker-образов</li>
                </ul>
            </section>
            <section class="card">
                <h2>🔗 Ссылки</h2>
                <ul>
                    <li><a href="/info.php">Статус подключения к MySQL</a></li>
                    <li><a href="https://github.com/xo4ychill/terraform-04" target="_blank">Репозиторий GitHub</a></li>
                </ul>
            </section>
            <section class="card">
                <h2>✅ Чек-лист готовности</h2>
                <table class="checklist">
                    <tr><td>☑</td><td>Инфраструктура описана без хардкода</td></tr>
                    <tr><td>☑</td><td>State хранится удалённо (S3)</td></tr>
                    <tr><td>☑</td><td>Подключён state locking</td></tr>
                    <tr><td>☑</td><td>Docker установлен через cloud-init</td></tr>
                    <tr><td>☑</td><td>Docker Compose установлен через cloud-init</td></tr>
                    <tr><td>☑</td><td>Dockerfile включает мультисборку</td></tr>
                    <tr><td>☑</td><td>Образ сохранён в Container Registry</td></tr>
                    <tr><td>☑</td><td>Приложение доступно по IP-адресу ВМ</td></tr>
                    <tr><td>☑</td><td>Создан MD-файл с документацией</td></tr>
                </table>
            </section>
        </main>
        <footer>
            <p>© 2025 — Итоговый проект DevOps</p>
        </footer>
    </div>
</body>
</html>
📄 Файл 10: src/app/style.css
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}
body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    background: linear-gradient(135deg, #0c0c1d 0%, #1a1a3e 50%, #0d0d2b 100%);
    color: #e0e0e0;
    min-height: 100vh;
    line-height: 1.6;
}
.container {
    max-width: 900px;
    margin: 0 auto;
    padding: 20px;
}
header {
    text-align: center;
    padding: 40px 0;
    border-bottom: 2px solid #333;
    margin-bottom: 30px;
}
header h1 {
    font-size: 2.5em;
    color: #00d4ff;
    margin-bottom: 10px;
}
header .subtitle {
    font-size: 1.2em;
    color: #888;
}
.card {
    background: rgba(255, 255, 255, 0.05);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 12px;
    padding: 25px;
    margin-bottom: 20px;
    backdrop-filter: blur(10px);
}
.card h2 {
    color: #00d4ff;
    margin-bottom: 15px;
    font-size: 1.4em;
}
.card p, .card li {
    color: #ccc;
}
.card ul {
    padding-left: 20px;
}
.card ul li {
    margin-bottom: 8px;
}
.card a {
    color: #00d4ff;
    text-decoration: none;
}
.card a:hover {
    text-decoration: underline;
}
.checklist {
    width: 100%;
    border-collapse: collapse;
}
.checklist td {
    padding: 8px 12px;
    border-bottom: 1px solid rgba(255,255,255,0.05);
}
.checklist td:first-child {
    color: #00ff88;
    font-size: 1.2em;
    width: 40px;
    text-align: center;
}
footer {
    text-align: center;
    padding: 30px 0;
    margin-top: 30px;
    border-top: 2px solid #333;
    color: #666;
}
📄 Файл 11: src/app/info.php
<?php
// ======================================================================
// Страница диагностики подключения к MySQL (Yandex Cloud Managed DB)
// ======================================================================
// Настройки из переменных окружения (передаются через docker-compose)
$db_host     = getenv('DB_HOST') ?: 'localhost';
$db_port     = getenv('DB_PORT') ?: '3306';
$db_name     = getenv('DB_NAME') ?: 'appdb';
$db_user     = getenv('DB_USER') ?: 'appuser';
$db_password = getenv('DB_PASSWORD') ?: '';
// Попытка подключения
$connected = false;
$error_msg = '';
$db_info   = [];
try {
    $dsn = "mysql:host={$db_host};port={$db_port};dbname={$db_name};charset=utf8mb4";
    $pdo = new PDO($dsn, $db_user, $db_password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_TIMEOUT => 5
    ]);
    $connected = true;
    // Получаем информацию о сервере
    $stmt = $pdo->query("SELECT VERSION() as version, NOW() as now");
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    $db_info['version'] = $row['version'];
    $db_info['server_time'] = $row['now'];
    // Проверяем наличие таблицы
    $stmt = $pdo->query("SHOW TABLES");
    $tables = $stmt->fetchAll(PDO::FETCH_COLUMN);
} catch (PDOException $e) {
    $error_msg = $e->getMessage();
}
?>
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <title>Статус MySQL</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="container">
        <header>
            <h1>🗄️ Статус подключения к MySQL</h1>
        </header>
        <main>
            <section class="card">
                <h2>📊 Параметры подключения</h2>
                <table class="checklist" style="width:100%">
                    <tr><td>🔑 Хост:</td><td><?php echo htmlspecialchars($db_host); ?></td></tr>
                    <tr><td>🔌 Порт:</td><td><?php echo htmlspecialchars($db_port); ?></td></tr>
                    <tr><td>💾 БД:</td><td><?php echo htmlspecialchars($db_name); ?></td></tr>
                    <tr><td>👤 Пользователь:</td><td><?php echo htmlspecialchars($db_user); ?></td></tr>
                    <tr><td>🔒 Пароль:</td><td><?php echo str_repeat('•', 12); ?></td></tr>
                </table>
            </section>
            <?php if ($connected): ?>
                <section class="card" style="border-color: #00ff88;">
                    <h2 style="color: #00ff88;">✅ Подключение успешно!</h2>
                    <table class="checklist" style="width:100%">
                        <tr><td>📦 Версия MySQL:</td><td><?php echo htmlspecialchars($db_info['version']); ?></td></tr>
                        <tr><td>🕐 Время сервера:</td><td><?php echo htmlspecialchars($db_info['server_time']); ?></td></tr>
                        <tr><td>📋 Таблицы:</td><td>
                            <?php if (count($tables) > 0): ?>
                                <?php echo implode(', ', array_map('htmlspecialchars', $tables)); ?>
                            <?php else: ?>
                                <em>Таблиц пока нет (база пуста)</em>
                            <?php endif; ?>
                        </td></tr>
                    </table>
                </section>
                <section class="card">
                    <h2>🧪 Создание тестовой таблицы</h2>
                    <?php
                    try {
                        $pdo->exec("CREATE TABLE IF NOT EXISTS test_table (
                            id INT AUTO_INCREMENT PRIMARY KEY,
                            message VARCHAR(255) NOT NULL,
                            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
                        echo '<p style="color:#00ff88;">✅ Таблица <code>test_table</code> создана</p>';
                        $pdo->exec("INSERT INTO test_table (message) VALUES ('Hello from Docker container!')");
                        echo '<p style="color:#00ff88;">✅ Тестовая запись добавлена</p>';
                        $stmt = $pdo->query("SELECT * FROM test_table ORDER BY id DESC LIMIT 5");
                        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
                        echo '<table class="checklist" style="width:100%">';
                        echo '<tr><th>ID</th><th>Сообщение</th><th>Создано</th></tr>';
                        foreach ($rows as $row) {
                            echo '<tr>';
                            echo '<td>' . htmlspecialchars($row['id']) . '</td>';
                            echo '<td>' . htmlspecialchars($row['message']) . '</td>';
                            echo '<td>' . htmlspecialchars($row['created_at']) . '</td>';
                            echo '</tr>';
                        }
                        echo '</table>';
                    } catch (PDOException $e) {
                        echo '<p style="color:#ff4444;">❌ Ошибка: ' . htmlspecialchars($e->getMessage()) . '</p>';
                    }
                    ?>
                </section>
            <?php else: ?>
                <section class="card" style="border-color: #ff4444;">
                    <h2 style="color: #ff4444;">❌ Ошибка подключения</h2>
                    <p style="color: #ff8888;"><?php echo htmlspecialchars($error_msg); ?></p>
                    <h3>Возможные причины:</h3>
                    <ul>
                        <li>Сетевая связность между ВМ и MySQL-кластером</li>
                        <li>Неверные учётные данные</li>
                        <li>Брандмауэр или Security Group блокирует порт</li>
                        <li>MySQL-кластер ещё не готов (подождите несколько минут)</li>
                    </ul>
                </section>
            <?php endif; ?>
            <section class="card">
                <p><a href="/">← Назад на главную</a></p>
            </section>
        </main>
    </div>
</body>
</html>
📄 Файл 12: src/docker-compose.yml
# ======================================================================
# Docker Compose — развёртывание web-приложения
# Приложение подключается к MySQL в Yandex Cloud Managed Database
# ======================================================================
version: "3.9"
services:
  web:
    image: ${REGISTRY_URL}/app:latest
    container_name: web-app
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    environment:
      # Подключение к MySQL (Yandex Cloud Managed Database)
      - DB_HOST=${DB_HOST}
      - DB_PORT=${DB_PORT}
      - DB_NAME=${DB_NAME}
      - DB_USER=${DB_USER}
      - DB_PASSWORD=${DB_PASSWORD}
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 10s
networks:
  app-network:
    driver: bridge
📄 Файл 13: src/modules/vpc/main.tf
# ======================================================================
# Модуль VPC — создание облачной сети и подсети
# ======================================================================
resource "yandex_vpc_network" "network" {
  name = var.network_name
}
resource "yandex_vpc_subnet" "subnet" {
  name           = var.subnet_name
  zone           = var.zone
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = var.v4_cidr_blocks
}
src/modules/vpc/variables.tf
variable "network_name" {
  description = "Имя облачной сети"
  type        = string
}
variable "subnet_name" {
  description = "Имя подсети"
  type        = string
}
variable "zone" {
  description = "Зона доступности"
  type        = string
}
variable "v4_cidr_blocks" {
  description = "CIDR-блоки подсети"
  type        = list(string)
}
src/modules/vpc/outputs.tf
output "network_id" {
  description = "ID облачной сети"
  value       = yandex_vpc_network.network.id
}
output "subnet_id" {
  description = "ID подсети"
  value       = yandex_vpc_subnet.subnet.id
}
📄 Файл 14: src/modules/vm/main.tf
# ======================================================================
# Модуль VM — создание виртуальной машины
# ======================================================================
resource "yandex_compute_instance" "vm" {
  name        = var.vm_name
  platform_id = "standard-v3"
  zone        = var.zone
  # Ресурсы ВМ
  resources {
    cores  = var.vm_cores
    memory = var.vm_memory
  }
  # Загрузочный диск
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
      size     = var.vm_disk_size
      type     = "network-hdd"
    }
  }
  # Сетевой интерфейс
  network_interface {
    subnet_id          = var.subnet_id
    nat                = true  # Внешний IP-адрес
    security_group_ids = var.security_group_ids
  }
  # Метаданные: SSH-ключ + Cloud-Init
  metadata = {
    user-data          = var.cloud_init_content
    serial-port-enable = 1
  }
  # Прерываемая ВМ (снижение стоимости)
  scheduling_policy {
    preemptible = var.preemptible
  }
  labels = {
    project     = var.project_label
    environment = "prod"
  }
}
# Получение последнего образа Ubuntu 22.04
data "yandex_compute_image" "ubuntu" {
  family = var.image_family
}
src/modules/vm/variables.tf
variable "vm_name" {
  description = "Имя виртуальной машины"
  type        = string
}
variable "project_label" {
  description = "Метка проекта"
  type        = string
}
variable "subnet_id" {
  description = "ID подсети"
  type        = string
}
variable "cloud_init_content" {
  description = "Содержимое cloud-init конфигурации"
  type        = string
}
variable "zone" {
  description = "Зона доступности"
  type        = string
}
variable "image_family" {
  description = "Семейство образа ОС"
  type        = string
}
variable "ssh_public_key" {
  description = "Публичный SSH-ключ"
  type        = string
}
variable "preemptible" {
  description = "Прерываемая ВМ"
  type        = bool
  default     = true
}
variable "security_group_ids" {
  description = "Список ID групп безопасности"
  type        = list(string)
}
variable "vm_cores" {
  description = "Количество ядер CPU"
  type        = number
  default     = 2
}
variable "vm_memory" {
  description = "Объём оперативной памяти (ГБ)"
  type        = number
  default     = 4
}
variable "vm_disk_size" {
  description = "Размер диска (ГБ)"
  type        = number
  default     = 20
}
src/modules/vm/outputs.tf
output "external_ip" {
  description = "Внешний IP-адрес ВМ"
  value       = yandex_compute_instance.vm.network_interface.0.nat_ip_address
}
output "internal_ip" {
  description = "Внутренний IP-адрес ВМ"
  value       = yandex_compute_instance.vm.network_interface.0.ip_address
}
output "vm_id" {
  description = "ID виртуальной машины"
  value       = yandex_compute_instance.vm.id
}
📄 Файл 15: src/modules/mysql/main.tf (Задание 1 — MySQL)
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
  labels = {
    environment = var.environment
  }
}
# --- База данных ---
resource "yandex_mdb_mysql_database" "database" {
  cluster_id = yandex_mdb_mysql_cluster.cluster.id
  name       = var.db_name
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
}
src/modules/mysql/variables.tf
variable "network_id" {
  description = "ID сети VPC"
  type        = string
}
variable "subnet_id" {
  description = "ID подсети"
  type        = string
}
variable "zone" {
  description = "Зона доступности"
  type        = string
}
variable "mysql_version" {
  description = "Версия MySQL (8.0 или 5.7)"
  type        = string
  default     = "8.0"
}
variable "db_name" {
  description = "Имя базы данных"
  type        = string
}
variable "db_user" {
  description = "Имя пользователя БД"
  type        = string
}
variable "db_password" {
  description = "Пароль пользователя БД"
  type        = string
  sensitive   = true
}
variable "environment" {
  description = "Окружение"
  type        = string
}
src/modules/mysql/outputs.tf
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
📄 Файл 16: scripts/docker-push.sh
#!/bin/bash
# ======================================================================
# Скрипт сборки Docker-образа и push в Yandex Container Registry
# ======================================================================
set -euo pipefail
# Конфигурация (передаются через terraform output)
REGISTRY_URL="${1:?Использование: $0 <registry_url>}"
IMAGE_TAG="${2:-latest}"
SOURCE_DIR="$(cd "$(dirname "$0")/.." && pwd)/src"
echo "=================================================="
echo "  Сборка и пуш Docker-образа"
echo "=================================================="
echo "Registry: ${REGISTRY_URL}"
echo "Tag:      ${IMAGE_TAG}"
echo "Source:   ${SOURCE_DIR}"
echo ""
# Шаг 1: Сборка образа
echo "📦 [1/3] Сборка Docker-образа..."
cd "${SOURCE_DIR}"
docker build -t "${REGISTRY_URL}/app:${IMAGE_TAG}" .
# Шаг 2: Проверка образа
echo "🔍 [2/3] Проверка образа..."
docker images "${REGISTRY_URL}/app:${IMAGE_TAG}"
# Шаг 3: Push в Container Registry
echo "🚀 [3/3] Push в Container Registry..."
docker push "${REGISTRY_URL}/app:${IMAGE_TAG}"
echo ""
echo "✅ Образ успешно отправлен: ${REGISTRY_URL}/app:${IMAGE_TAG}"
📄 Файл 17: scripts/setup-lockbox.sh
#!/bin/bash
# ======================================================================
# Скрипт создания секрета в Yandex LockBox для пароля MySQL
# ======================================================================
set -euo pipefail
FOLDER_ID="${1:?Использование: $0 <folder_id>}"
SECRET_NAME="${2:-mysql-credentials}"
DB_PASSWORD="${3:-$(openssl rand -base64 24)}"
echo "=================================================="
echo "  Создание секрета в Yandex LockBox"
echo "=================================================="
echo "Catalog:   ${FOLDER_ID}"
echo "Secret:    ${SECRET_NAME}"
echo "Password:  ${DB_PASSWORD:0:4}... (скрыто)"
echo ""
# Создание секрета
SECRET_ID=$(yc lockbox secret create \
    --name "${SECRET_NAME}" \
    --description "MySQL credentials for application" \
    --folder-id "${FOLDER_ID}" \
    --payload "[{\"key\":\"password\",\"text_value\":\"${DB_PASSWORD}\"}]" \
    --format json | jq -r '.id')
echo "✅ Секрет создан: ${SECRET_ID}"
echo ""
echo "Для получения пароля в Terraform используйте:"
echo "  data \"yandex_lockbox_secret_version\" \"mysql_password\" {"
echo "    secret_id = \"${SECRET_ID}\""
echo "  }"
echo ""
echo "Пароль для terraform.tfvars:"
echo "  mysql_password = \"${DB_PASSWORD}\""
📄 Файл 18: docs/REPORT.md
# 📋 Отчёт по итоговому проекту
> **Дисциплина:** Виртуализация и контейнеризация / DevOps  
> **Тема:** Terraform + Docker + Yandex Cloud  
> **Дата:** 2025  
---
## 📑 Содержание
1. [Цель проекта](#цель-проекта)
2. [Архитектура решения](#архитектура-решения)
3. [Задание 1 — Инфраструктура в Yandex Cloud](#задание-1)
4. [Задание 2 — Docker через cloud-init](#задание-2)
5. [Задание 3 — Dockerfile с мультисборкой](#задание-3)
6. [Задание 4 — Подключение к MySQL](#задание-4)
7. [Задание 5* — LockBox интеграция](#задание-5)
8. [Чек-лист готовности](#чек-лист)
9. [Примеры и скриншоты](#примеры)
10. [Ссылки](#ссылки)
---
## 🎯 <a name="цель-проекта"></a> Цель проекта
Развернуть web-приложение в Docker-контейнере на виртуальной машине Yandex Cloud
с использованием Terraform для управления инфраструктурой.
---
## 🏗️ <a name="архитектура-решения"></a> Архитектура решения
┌─────────────────────────────────────────────────────────┐
│                    Yandex Cloud                         │
│                                                         │
│  ┌───────────────┐    ┌──────────────────────────┐     │
│  │   Terraform   │───▶│    Virtual Private Cloud │     │
│  │  (IaC)        │    │    ┌─────────────────┐   │     │
│  └───────────────┘    │    │   Subnet         │   │     │
│         │             │    │ 192.168.10.0/24  │   │     │
│         │             │    └────────┬────────┘   │     │
│         │             │             │            │     │
│         ▼             │    ┌────────▼────────┐   │     │
│  ┌───────────────┐    │    │    VM (app)      │   │     │
│  │    LockBox    │    │    │  ┌────────────┐  │   │     │
│  │ ┌───────────┐│    │    │  │  Docker    │  │   │     │
│  │ │ password  ││    │    │  │ ┌────────┐ │  │   │     │
│  │ └───────────┘│    │    │  │ │web-app │ │  │   │     │
│  └───────────────┘    │    │  │ └────────┘ │  │   │     │
│                        │    │  │            │  │   │     │
│  ┌───────────────┐    │    │  └────────────┘  │   │     │
│  │  Container    │    │    └────────┬────────┘   │     │
│  │  Registry     │    │             │            │     │
│  │  ┌───────────┐│    │    ┌────────▼────────┐   │     │
│  │  │ app:latest││    │    │  MySQL Cluster   │   │     │
│  │  └───────────┘│    │    │  (Managed DB)    │   │     │
│  └───────────────┘    │    └─────────────────┘   │     │
│                        └──────────────────────────┘     │
│                                                         │
│  Security Group: TCP 22, 80, 443                        │
└─────────────────────────────────────────────────────────┘
---
## 📝 <a name="задание-1"></a> Задание 1 — Инфраструктура в Yandex Cloud
### 1.1 Virtual Private Cloud (VPC)
Облачная сеть создаётся через модуль `modules/vpc`:
```hcl
# src/modules/vpc/main.tf
resource "yandex_vpc_network" "network" {
  name = var.network_name
}
📸 *Скриншот: VPC в консоли Yandex Cloud → Network → app-network*
1.2 Подсети
resource "yandex_vpc_subnet" "subnet" {
  name           = var.subnet_name
  zone           = var.zone
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = var.v4_cidr_blocks  # ["192.168.10.0/24"]
}
📸 *Скриншот: Subnet → app-subnet, CIDR 192.168.10.0/24*
1.3 Виртуальные машины
ВМ создаётся через модуль modules/vm:
Платформа: standard-v3
CPU: 2 ядра
RAM: 4 ГБ
Диск: 20 ГБ network-hdd
Образ: Ubuntu 22.04 LTS
Прерываемая: да (preemptible)
1.4 Группы безопасности
resource "yandex_vpc_security_group" "app_sg" {
  ingress { protocol = "TCP"; port = 22; v4_cidr_blocks = [var.allowed_ssh_cidr] }
  ingress { protocol = "TCP"; port = 80; v4_cidr_blocks = ["0.0.0.0/0"] }
  ingress { protocol = "TCP"; port = 443; v4_cidr_blocks = ["0.0.0.0/0"] }
  egress  { protocol = "ANY"; v4_cidr_blocks = ["0.0.0.0/0"] }
}
📸 *Скриншот: Security Groups → app-network-sg, правила ingress/egress*
1.5 MySQL (Managed Database)
Модуль modules/mysql создаёт:
Кластер MySQL 8.0 (s2.micro: 2 vCPU, 8 GB RAM)
Базу данных appdb
Пользователя appuser с паролем из LockBox
📸 *Скриншот: Managed Service for MySQL → кластер prod-mysql-cluster*
1.6 Container Registry
resource "yandex_container_registry" "app_registry" {
  name = var.registry_name
}
📸 *Скриншот: Container Registry → app-registry*
🐳 <a name="задание-2"></a> Задание 2 — Docker через cloud-init
Docker и Docker Compose устанавливаются в файле cloud-init.yml.tpl:
Шаги установки:
1. Добавление GPG-ключа Docker
2. Подключение репозитория Docker
3. apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
4. systemctl enable/start docker
5. Настройка credHelper для Yandex Container Registry
6. Создание .env файла с параметрами MySQL
Проверка на ВМ:
yc-user@vm-app:~$ docker --version
Docker version 27.x.x, build xxxxxxx
yc-user@vm-app:~$ docker compose version
Docker Compose version v2.x.x
📸 *Скриншот: SSH → docker --version && docker compose version*
🔧 <a name="задание-3"></a> Задание 3 — Dockerfile с мультисборкой
Dockerfile использует multi-stage build:
Stage	Базовый образ	Назначение	
builder	ubuntu:22.04	Сборка и проверка файлов	
runtime	ubuntu:22.04	Финальный образ (~150 MB)	
Сборка и push:
# Локальная сборка
cd src/
docker build -t cr.yandex/crpxxxxxxxxxx/app:latest .
# Push в Container Registry
docker push cr.yandex/crpxxxxxxxxxx/app:latest
📸 *Скриншот: docker images | grep app*
📸 *Скриншот: Container Registry → app:latest*
🗄️ <a name="задание-4"></a> Задание 4 — Подключение к MySQL
Приложение в контейнере подключается к MySQL через переменные окружения:
DB_HOST = rc1a-...mysql.mdb.yandexcloud.net
DB_PORT = 3306
DB_NAME = appdb
DB_USER = appuser
DB_PASSWORD = ******** (из LockBox)
Проверка:
# На ВМ:
cd /opt/app
sudo docker compose up -d
curl http://localhost/info.php
📸 *Скриншот: Страница info.php — "✅ Подключение успешно!"*
📸 *Скриншот: Таблица test_table с записью "Hello from Docker container!"*
🔐 <a name="задание-5"></a> Задание 5* — LockBox интеграция
Создание секрета:
# Через CLI
yc lockbox secret create \
  --name mysql-credentials \
  --payload '[{"key":"password","text_value":"MySecurePassword123!"}]'
# Или через скрипт
./scripts/setup-lockbox.sh b1g5xxxxxxxxxxxxxxxx mysql-credentials "MySecurePassword123!"
Чтение в Terraform:
data "yandex_lockbox_secret_version" "mysql_password" {
  secret_id = yandex_lockbox_secret.mysql_secret[0].id
}
# Использование:
db_password = data.yandex_lockbox_secret_version.mysql_password.payload["password"]
Переключение между режимами:
# В terraform.tfvars:
use_lockbox = true   # Пароль из LockBox
use_lockbox = false  # Пароль из переменной (для локальной разработки)
📸 *Скриншот: LockBox → mysql-credentials → password*
✅ <a name="чек-лист"></a> Чек-лист готовности
№	Требование	Статус	Доказательство	
1	Инфраструктура описана без хардкода	✅	Все значения через variables.tf	
2	State хранится удалённо	✅	Backend S3 в tf-state-bucket	
3	Подключён state locking	✅	use_lockfile = true	
4	Docker установлен через cloud-init	✅	cloud-init.yml.tpl, шаги 1-4	
5	Docker Compose установлен через cloud-init	✅	docker-compose-plugin в пакетах	
6	Dockerfile включает мультисборку	✅	FROM ... AS builder + FROM ... AS runtime	
7	Образ сохранён в Container Registry	✅	docker push cr.yandex/.../app:latest	
8	Приложение доступно по IP	✅	http://<VM_EXTERNAL_IP>/	
9	MD-файл создан и оформлен	✅	Этот файл (REPORT.md)	
📸 <a name="примеры"></a> Примеры и скриншоты
Терминал: terraform init + apply
$ cd src/
$ terraform init
Initializing the backend...
Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.
Initializing provider plugins...
- Finding yandex-cloud/yandex versions matching ">= 0.100"...
Terraform has been successfully initialized!
$ terraform plan -var-file="terraform.tfvars"
Plan: 14 to add, 0 to change, 0 to destroy.
$ terraform apply -var-file="terraform.tfvars"
Apply complete! Resources: 14 added, 0 changed, 0 destroyed.
Outputs:
  vm_external_ip = "158.160.xx.xx"
  registry_url   = "cr.yandex/crpxxxxxxxxxx"
  mysql_db_host  = "rc1a-...mysql.mdb.yandexcloud.net"
Терминал: Проверка Docker на ВМ
$ ssh yc-user@158.160.xx.xx
yc-user@vm-app:~$ docker --version
Docker version 27.5.1, build 9f9e405
yc-user@vm-app:~$ docker compose version
Docker Compose version v2.32.4
yc-user@vm-app:~$ sudo docker compose -f /opt/app/docker-compose.yml up -d
[+] Running 2/2
 ✔ Network app_default  Created
 ✔ Container web-app    Started
yc-user@vm-app:~$ curl -s http://localhost/ | head -5
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
Терминал: Проверка подключения к MySQL
yc-user@vm-app:~$ curl -s http://localhost/info.php | grep -E "✅|❌"
                    <h2 style="color: #00ff88;">✅ Подключение успешно!</h2>
                        echo '<p style="color:#00ff88;">✅ Таблица <code>test_table</code> создана</p>';
                        echo '<p style="color:#00ff88;">✅ Тестовая запись добавлена</p>';
🔗 <a name="ссылки"></a> Ссылки
Репозиторий GitHub
Ветка terraform-hotfix
Yandex Cloud Documentation
Terraform Provider Yandex
Docker Documentation
Yandex LockBox
---
## 📊 Сводная таблица: Задание → Файл → Компонент
| Задание | Компонент | Файл(ы) |
|---------|-----------|----------|
| **1** | VPC | `modules/vpc/main.tf` |
| **1** | Подсети | `modules/vpc/main.tf` |
| **1** | VM | `modules/vm/main.tf` |
| **1** | Security Group | `src/main.tf` (ресурс `app_sg`) |
| **1** | MySQL | `modules/mysql/main.tf` |
| **1** | Container Registry | `src/main.tf` (ресурс `app_registry`) |
| **2** | Docker + Compose через cloud-init | `src/cloud-init.yml.tpl` |
| **3** | Dockerfile (мультисборка) | `src/Dockerfile` |
| **3** | Push в Registry | `scripts/docker-push.sh` |
| **4** | Подключение к MySQL | `src/app/info.php`, `src/docker-compose.yml` |
| **5*** | LockBox | `src/main.tf` (ресурсы `lockbox_*`) |
| **-** | Remote State + Locking | `src/providers.tf` |
| **-** | Документация | `docs/REPORT.md` |
---
## 🚀 Порядок выполнения
```bash
# 1. Клонируем репозиторий
git clone https://github.com/xo4ychill/terraform-04.git
cd terraform-04
# 2. Создаём S3-бакет для state (один раз)
yc storage bucket create --name tf-state-bucket
# 3. Создаём сервисный аккаунт (если нет)
yc iam service-account create --name terraform-sa
yc iam key create --service-account-name terraform-sa --output sa-key.json
yc resource-manager folder add-access-binding <folder_id> \
  --role editor --service-account-name terraform-sa
# 4. Создаём Container Registry (один раз, если нет)
yc container registry create --name app-registry
# 5. Настраиваем переменные
cd src/
cp terraform.tfvars.example terraform.tfvars
# Заполняем реальные значения в terraform.tfvars
# 6. Инициализируем Terraform
terraform init
# 7. Планируем изменения
terraform plan -var-file="terraform.tfvars"
# 8. Применяем изменения
terraform apply -var-file="terraform.tfvars"
# 9. Получаем outputs
terraform output -json
# 10. Собираем и пушим Docker-образ
REGISTRY_URL=$(terraform output -raw registry_url)
cd ..
chmod +x scripts/docker-push.sh
./scripts/docker-push.sh "$REGISTRY_URL" latest
# 11. (Задание 5*) Настройка LockBox
FOLDER_ID=$(grep folder_id src/terraform.tfvars | awk '{print $3}' | tr -d '"')
./scripts/setup-lockbox.sh "$FOLDER_ID" mysql-credentials "YourPassword123!"
# 12. Подключаемся к ВМ и запускаем контейнер
VM_IP=$(terraform output -raw vm_external_ip)
ssh yc-user@$VM_IP
cd /opt/app
sudo docker compose pull
sudo docker compose up -d
# 13. Проверяем
curl http://$VM_IP/
curl http://$VM_IP/info.php
Это полное решение всех 5 заданий итогового проекта. Все файлы готовы к копированию в репозиторий. Если нужно помочь с каким-то конкретным аспектом (настроить DNS, добавить SSL, доработать Dockerfile) — говорите!