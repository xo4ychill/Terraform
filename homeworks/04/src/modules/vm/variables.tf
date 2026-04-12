variable "vm_name" {}
variable "project_label" {}
variable "subnet_id" {}
variable "cloud_init_content" {}
variable "zone" {}
variable "image_family" {}
variable "preemptible" {
  default = true
}

variable "ssh_public_key" {
  description = "Публичный SSH-ключ"
  type        = string
  sensitive   = true
}