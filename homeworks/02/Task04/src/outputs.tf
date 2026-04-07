output "vm_info" {

  description = "Information about all VMs"

output "vm_info" {

  value = [
    { web = ["ssh -o 'StrictHostKeyChecking=no' ubuntu@${yandex_compute_instance.example-a.network_interface[0].nat_ip_address}", yandex_compute_instance.example-a.network_interface[0].ip_address] },
    { db = ["ssh -o 'StrictHostKeyChecking=no' ubuntu@${yandex_compute_instance.example-b.network_interface[0].nat_ip_address}", yandex_compute_instance.example-b.network_interface[0].ip_address] },
  ]
 }
}