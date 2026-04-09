[webservers]
%{ for vm in web_vms ~}
${vm.name} ansible_host=${vm.ip} fqdn=${vm.fqdn}
%{ endfor ~}

[databases]
%{ for vm in db_vms ~}
${vm.name} ansible_host=${vm.ip} fqdn=${vm.fqdn}
%{ endfor ~}

[storage]
${storage_vm.name} ansible_host=${storage_vm.ip} fqdn=${storage_vm.fqdn}