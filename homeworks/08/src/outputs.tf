output "marketing_external_ip" {
  value = module.marketing_vm.external_ip
}

output "analytics_external_ip" {
  value = module.analytics_vm.external_ip
}

output "marketing_internal_ip" {
  value = module.marketing_vm.internal_ip
}

output "analytics_internal_ip" {
  value = module.analytics_vm.internal_ip
}