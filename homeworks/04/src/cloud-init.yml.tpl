#cloud-config

users:
  - name: yc-user
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_authorized_keys:
      - ${ssh_key}


package_update: true

packages:
  - nginx
runcmd:
  - systemctl enable nginx
  - systemctl start nginx