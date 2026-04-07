#################################
# VPC NETWORK
#################################

resource "yandex_vpc_network" "develop" {
  name = var.vpc_name
}

#################################
# SUBNET A (для WEB VM)
#################################

resource "yandex_vpc_subnet" "develop_a" {

  name           = "${var.vpc_name}-a"
  zone           = var.default_zone
  network_id     = yandex_vpc_network.develop.id
  v4_cidr_blocks = var.default_cidr

}

#################################
# SUBNET B (для DB VM)
#################################

resource "yandex_vpc_subnet" "develop_b" {

  name           = "${var.vpc_name}-b"
  zone           = var.vm_db_zone
  network_id     = yandex_vpc_network.develop.id
  v4_cidr_blocks = ["10.0.2.0/24"]

}

#################################
# IMAGE
#################################

data "yandex_compute_image" "ubuntu" {
  family = var.vm_image_family
}

#################################
# WEB VM
#################################

resource "yandex_compute_instance" "web" {

  name     = local.vm_web_name
  hostname = local.vm_web_name

  platform_id = var.vm_web_platform_id
  zone        = var.default_zone

  resources {

    cores         = var.vm_web_cores
    memory        = var.vm_web_memory
    core_fraction = var.vm_web_core_fraction

  }

  boot_disk {

    initialize_params {

      image_id = data.yandex_compute_image.ubuntu.image_id
      size     = 10
      type     = "network-hdd"

    }

  }

  scheduling_policy {

    preemptible = true

  }

  network_interface {

    subnet_id = yandex_vpc_subnet.develop_a.id
    nat       = true

  }

  metadata = {

    serial-port-enable = 1
    ssh-keys           = "ubuntu:${var.vms_ssh_root_key}"

  }

}

#################################
# DB VM
#################################

resource "yandex_compute_instance" "db" {

  name     = local.vm_db_name
  hostname = local.vm_db_name

  platform_id = var.vm_db_platform_id
  zone        = var.vm_db_zone

  resources {

    cores         = var.vm_db_cores
    memory        = var.vm_db_memory
    core_fraction = var.vm_db_core_fraction

  }

  boot_disk {

    initialize_params {

      image_id = data.yandex_compute_image.ubuntu.image_id
      size     = 10
      type     = "network-hdd"

    }

  }

  scheduling_policy {

    preemptible = true

  }

  network_interface {

    subnet_id = yandex_vpc_subnet.develop_b.id
    nat       = true

  }

  metadata = {

    serial-port-enable = 1
    ssh-keys           = "ubuntu:${var.vms_ssh_root_key}"

  }

}