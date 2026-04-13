# ======================================================================
# Модуль VM — создание виртуальной машины
# ======================================================================

resource "yandex_compute_instance" "vm" {
  name        = var.vm_name
  platform_id = "standard-v3"
  zone        = var.zone

  # Ресурсы ВМ
  resources {
    cores  = var.vm_cores
    memory = var.vm_memory
  }

  # Загрузочный диск
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
      size     = var.vm_disk_size
      type     = "network-hdd"
    }
  }

  # Сетевой интерфейс
  network_interface {
    subnet_id          = var.subnet_id
    nat                = true  # Внешний IP-адрес
    security_group_ids = var.security_group_ids
  }

  # Метаданные: SSH-ключ + Cloud-Init
  metadata = {
    user-data          = var.cloud_init_content
    serial-port-enable = 1
  }

  # Прерываемая ВМ (снижение стоимости)
  scheduling_policy {
    preemptible = var.preemptible
  }

  labels = {
    project     = var.project_label
    environment = "prod"
  }
}

# Получение последнего образа Ubuntu 22.04
data "yandex_compute_image" "ubuntu" {
  family = var.image_family
}
