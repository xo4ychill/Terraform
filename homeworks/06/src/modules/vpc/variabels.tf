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
