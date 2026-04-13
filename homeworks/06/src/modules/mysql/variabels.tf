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
