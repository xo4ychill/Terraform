variable "vm_name" {}
variable "project_label" {}
variable "subnet_id" {}
variable "zone" {}
variable "image_family" {}
variable "ssh_public_key" {}
variable "cloud_init_content" {}
variable "preemptible" {}

variable "security_group_ids" {
  type = list(string)
}