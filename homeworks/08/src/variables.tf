variable "cloud_id" {
  type = string
}

variable "folder_id" {
  type = string
}

variable "default_zone" {
  type    = string
  default = "ru-central1-a"
}

variable "service_account_key_file" {
  description = "Path to service account key JSON"
  type        = string
  sensitive   = true
}

variable "vpc_name" {
  type = string
}

variable "subnet_name" {
  type = string
}

variable "v4_cidr_blocks" {
  type = list(string)
}

variable "image_family" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "allowed_ssh_cidr" {
  type = string
}

variable "environment" {
  type = string
}

# ==================== ВАЛИДАЦИЯ IP-АДРЕСОВ ====================
variable "single_ip" {
  description = "ip-адрес"
  type        = string

  validation {
    condition     = can(regex("^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", var.single_ip))
    error_message = "Значение должно быть корректным IPv4-адресом. Пример: 192.168.0.1"
  }
}

variable "ip_list" {
  description = "список ip-адресов"
  type        = list(string)

  validation {
    condition = alltrue([
      for ip in var.ip_list : can(regex("^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", ip))
    ])
    error_message = "Все элементы списка должны быть корректными IPv4-адресами. Пример: ['192.168.0.1', '1.1.1.1']"
  }
}