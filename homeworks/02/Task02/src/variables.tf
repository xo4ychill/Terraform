### image vars

variable "vm_web_image_family" {
  type        = string
  default     = "ubuntu-2004-lts"
  description = "Image family for VM"
}

### vm vars

variable "vm_web_name" {
  type    = string
  default = "netology-develop-platform-web"
}

variable "vm_web_hostname" {
  type    = string
  default = "netology-develop-platform-web"
}

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

variable "vm_web_boot_disk_size" {
  type    = number
  default = 10
}

variable "vm_web_boot_disk_type" {
  type    = string
  default = "network-hdd"
}

variable "vm_web_preemptible" {
  type    = bool
  default = true
}

variable "vm_web_nat" {
  type    = bool
  default = true
}

variable "vm_web_serial_port_enable" {
  type    = number
  default = 1
}

### cloud vars

variable "cloud_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
}

variable "folder_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-a"
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}
variable "default_cidr" {
  type        = list(string)
  default     = ["10.0.1.0/24"]
  description = "https://cloud.yandex.ru/docs/vpc/operations/subnet-create"
}

variable "vpc_name" {
  type        = string
  default     = "develop"
  description = "VPC network & subnet name"
}


###ssh vars

variable "vms_ssh_root_key" {
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCfEfuBB+/Gz3a2s+HRS96m+W3hKj41JVxNpDpsuFAwix8MrG0tOpGZFH3Hmh1Iy2mCYTacGOaVKgHy3vu6qJkNkWhZjA5ZvJOkaFxzaF/bG+apSD2BdpK2ig4VXHJg0qVjLmQmXCzqg2xhg4P4i++8oY0pPmf2nreN6O8rsIDys2ZNCPPg0I1YFO5wi6JMIJiJ/j8CaGUBFjAe0A2nshTpIIB14Zjqmh74KAfHssem5Awf09DwaZeIYgNPLpS++j2xKd1TZqbyxauuUWzbh2h6ERRSVIiLu+kSIfLMZy/rSR5D+qVygvNOlD1xWq8fePcEy4/dAt45w9b0zv9K7pawq88jdf4c1XK4O5aqvAjPS8HGO1c8+Z5qR2WAhRgYlfWSgdz9XgDYTQlcmuzHhhHDBz1ywjmOdHfD6nmBhSB+YFX/m9WO5cZte4O9YVoNnDD+kX4xU6AocdCEzxuKmXy7fDlDZJ9Kf266qS+6/BlC700938Dk9fcn0qaxXYMh3zwj+8gRpYuDxzRD7G+Y8dHBofJs6xtUtYjkO/17N4k7C93+dPYWc+KrlUyEZteCp7VIA111fgNl6zpbHOyyNLd4FTyyTgCyh9VaZUr/iWui0ZoQmdq5OPNJeYH7yXDmLIqS0oV8PNyM7y+JLtJ4GgZj2GTG5Fp/3Tg1WEcjJMg8qQ== xo4y.chill@yandex.ru"
  description = "ssh-keygen -t ed25519"
}

