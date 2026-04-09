# WEB ВМ
output "web_vm_info" {
  description = "Info about all WEB VMs including IP, CPU, RAM, Disk"
  value = [
    for vm in yandex_compute_instance.web : {
      name        = vm.name
      ip          = vm.network_interface.0.nat_ip_address
      cores       = vm.resources.0.cores
      memory      = vm.resources.0.memory
      disk_volume = vm.boot_disk.0.initialize_params.0.size
    }
  ]
}

# DB ВМ
output "db_vm_info" {
  description = "Info about all DB VMs including IP, CPU, RAM, Disk"
  value = {
    for name, vm in yandex_compute_instance.db : name => {
      ip          = vm.network_interface.0.nat_ip_address
      cores       = vm.resources.0.cores
      memory      = vm.resources.0.memory
      disk_volume = vm.boot_disk.0.initialize_params.0.size
    }
  }
}

# Storage ВМ
output "storage_vm_info" {
  description = "Info about storage VM and attached extra disks"
  value = {
    name      = yandex_compute_instance.storage.name
    ip        = yandex_compute_instance.storage.network_interface.0.nat_ip_address
    cores     = yandex_compute_instance.storage.resources.0.cores
    memory    = yandex_compute_instance.storage.resources.0.memory
    boot_disk = yandex_compute_instance.storage.boot_disk.0.initialize_params.0.size
    extra_disks = [
      for disk in yandex_compute_disk.extra_disks : {
        name = disk.name
        size = disk.size
      }
    ]
  }
}
