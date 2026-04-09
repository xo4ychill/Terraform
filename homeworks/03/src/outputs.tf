output "all_vms" {

  description = "All VMs (count + for_each) as list of objects"

  value = [
    for vm in flatten([
      values(yandex_compute_instance.db),
      yandex_compute_instance.web
    ]) : {
      name = vm.name
      id   = vm.id
      fqdn = vm.fqdn
    }
  ]

}