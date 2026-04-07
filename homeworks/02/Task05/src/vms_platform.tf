################################
# WEB VM
################################

variable "vm_web_platform_id" {
  type    = string
  default = "standard-v2"
}

variable "vm_web_cores" {
  type    = number
  default = 2
}

variable "vm_web_memory" {
  type    = number
  default = 1
}

variable "vm_web_core_fraction" {
  type    = number
  default = 5
}

################################
# DB VM
################################

variable "vm_db_platform_id" {
  type    = string
  default = "standard-v2"
}

variable "vm_db_cores" {
  type    = number
  default = 2
}

variable "vm_db_memory" {
  type    = number
  default = 2
}

variable "vm_db_core_fraction" {
  type    = number
  default = 20
}

variable "vm_db_zone" {
  type    = string
  default = "ru-central1-b"
}