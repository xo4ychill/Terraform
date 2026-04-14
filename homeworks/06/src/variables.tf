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
  default     = 10
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