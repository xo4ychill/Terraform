output "vm_info" {

  description = "Information about all VMs"

  value = {

    web = {
      instance_name = yandex_compute_instance.web.name
      external_ip   = yandex_compute_instance.web.network_interface[0].nat_ip_address
      fqdn          = yandex_compute_instance.web.fqdn
    }

    db = {
      instance_name = yandex_compute_instance.db.name
      external_ip   = yandex_compute_instance.db.network_interface[0].nat_ip_address
      fqdn          = yandex_compute_instance.db.fqdn
    }

  }

}