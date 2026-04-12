output "vm_ips" {
  value = {
    marketing  = module.marketing_vm.external_ip
    analytics  = module.analytics_vm.external_ip
  }
}