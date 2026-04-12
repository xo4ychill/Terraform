data "yandex_compute_image" "develop" {
  family = var.image_family
}

resource "yandex_compute_instance" "develop" {
  name        = var.vm_name
  platform_id = "standard-v3"
  zone        = var.zone

  resources {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.develop.id
      size     = 10
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id = var.subnet_id
    nat       = true
  }

  metadata = {
    user-data = var.cloud_init_content
    serial-port-enable = "1"
    ssh-keys           = "yc-user:${var.ssh_public_key}"
  }

  labels = {
    project = var.project_label
    env     = "test"
  }

  scheduling_policy {
    preemptible = var.preemptible
  }

  allow_stopping_for_update = true

}