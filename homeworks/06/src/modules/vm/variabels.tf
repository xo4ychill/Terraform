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
