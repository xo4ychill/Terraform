
# Создаем 3 дополнительных диска
resource "yandex_compute_disk" "extra_disks" {

  count = 3

  name = "extra-disk-${count.index + 1}"
  zone = var.default_zone
  type = "network-hdd"
  size = 1
}

# VM storage
resource "yandex_compute_instance" "storage" {

  name        = "storage"
  hostname    = "storage"
  platform_id = "standard-v3"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
      type     = "network-hdd"
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

  metadata = {
    ssh-keys = "ubuntu:${local.ssh_key}"
  }

  # Подключение дополнительных дисков через dynamic + for_each
  dynamic "secondary_disk" {

    for_each = yandex_compute_disk.extra_disks

    content {
      disk_id = secondary_disk.value.id
    }

  }

  # ЯВНАЯ зависимость
  depends_on = [
    yandex_compute_disk.extra_disks
  ]
}
