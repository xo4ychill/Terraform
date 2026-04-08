resource "yandex_compute_instance" "web" {
  count       = 2
  name        = "web-${count.index + 1}"
  platform_id = "standard-v3"

  resources {
    cores         = var.vms_resources["web"].cores
    memory        = var.vms_resources["web"].memory
    core_fraction = var.vms_resources["web"].core_fraction
  }

  boot_disk {
    initialize_params {
      size     = var.vms_resources["web"].hdd_size
      type     = var.vms_resources["web"].hdd_type
      image_id = data.yandex_compute_image.ubuntu.id
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.develop.id
    nat       = true
  }

  scheduling_policy {
    preemptible = true
  }

  allow_stopping_for_update = true

  metadata = merge(
    var.metadata,
    {
      ssh-keys = "ubuntu:${local.ssh_key}"
    }
  )

  depends_on = [
    yandex_compute_instance.db
  ]
}