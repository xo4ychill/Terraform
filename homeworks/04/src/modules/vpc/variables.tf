variable "network_name" {
  description = "Название VPC сети"
  type        = string
}

variable "subnet_name" {
  description = "Название подсети"
  type        = string
}

variable "zone" {
  description = "Зона доступности для подсети"
  type        = string
}

variable "v4_cidr_blocks" {
  description = "CIDR блок для подсети"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

