resource "yandex_compute_instance" "vm" {
  name = var.vm_name

  allow_stopping_for_update = true

  resources {
    cores  = 2
    memory = 1
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.image.id
    }
  }

  network_interface {
    subnet_id          = var.subnet_id
    nat                = true
    security_group_ids = var.security_group_ids
  }

  metadata = {
    user-data = var.cloud_init_content
  }

  scheduling_policy {
    preemptible = var.preemptible
  }

  labels = {
    project = var.project_label
  }
}

data "yandex_compute_image" "image" {
  family = var.image_family
}