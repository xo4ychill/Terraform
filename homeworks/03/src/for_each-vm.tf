resource "yandex_compute_instance" "db" {
  for_each = { for vm in var.each_vm : vm.vm_name => vm }

  name        = each.value.vm_name
  platform_id = "standard-v3"

  resources {
    cores  = each.value.cpu
    memory = each.value.ram
  }

  boot_disk {
    initialize_params {
      size     = each.value.disk_volume
      type     = "network-hdd"
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
}