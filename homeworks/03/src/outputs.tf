# WEB VM outputs
output "web_vm_info" {
  description = "Information about all WEB VMs including IP, CPU, RAM and disk"
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

# DB VM outputs
output "db_vm_info" {
  description = "Information about all DB VMs including IP, CPU, RAM and disk"
  value = {
    for name, vm in yandex_compute_instance.db : name => {
      ip          = vm.network_interface.0.nat_ip_address
      cores       = vm.resources.0.cores
      memory      = vm.resources.0.memory
      disk_volume = vm.boot_disk.0.initialize_params.0.size
    }
  }
}