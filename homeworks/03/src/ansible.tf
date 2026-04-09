resource "local_file" "ansible_inventory" {

  filename = "${path.module}/inventory.ini"

  content = templatefile("${path.module}/inventory.tpl", {

    web_vms = [
      for vm in yandex_compute_instance.web : {
        name = vm.name
        ip   = vm.network_interface[0].nat_ip_address
        fqdn = vm.fqdn
      }
    ]

    db_vms = [
      for vm in yandex_compute_instance.db : {
        name = vm.name
        ip   = vm.network_interface[0].nat_ip_address
        fqdn = vm.fqdn
      }
    ]

    storage_vm = {
      name = yandex_compute_instance.storage.name
      ip   = yandex_compute_instance.storage.network_interface[0].nat_ip_address
      fqdn = yandex_compute_instance.storage.fqdn
    }

  })
}
