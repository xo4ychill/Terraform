# ======================================================================
# Модуль VM — создание виртуальной машины
# ======================================================================

data "yandex_compute_image" "ubuntu" {
  family = var.image_family
}

resource "yandex_compute_instance" "vm" {
  name        = var.vm_name
  description = "VM for ${var.project_label} in ${var.environment_label}"
  platform_id = "standard-v3"
  zone        = var.zone
  
  resources {
    cores  = var.vm_cores
    memory = var.vm_memory
  }
  
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
      size     = var.vm_disk_size
      type     = "network-hdd"
    }
  }
  
  network_interface {
    subnet_id          = var.subnet_id
    nat                = true
    security_group_ids = var.security_group_ids
  }
  
  metadata = {
    user-data          = var.cloud_init_content
    serial-port-enable = 1
  }
  
  scheduling_policy {
    preemptible = var.preemptible
  }
  
  labels = {
    project     = var.project_label
    environment = var.environment_label
    managed_by  = "terraform"
  }
}