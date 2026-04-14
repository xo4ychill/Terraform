# --- VPC ---
module "vpc" {
  source = "./modules/vpc"

  network_name   = var.vpc_name
  subnet_name    = var.subnet_name
  zone           = var.default_zone
  v4_cidr_blocks = var.v4_cidr_blocks
}

# --- Security Group ---
resource "yandex_vpc_security_group" "dev_sg" {
  name        = "${var.vpc_name}-sg"
  network_id  = module.vpc.network_id
  description = "Security group"

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  labels = {
    environment = var.environment
  }
}

# --- Cloud-init ---
locals {
  ssh_key_content = var.ssh_public_key

  cloud_init_content = templatefile("${path.module}/cloud-init.yml.tpl", {
    ssh_key = local.ssh_key_content
  })
}

# --- Marketing VM ---
module "marketing_vm" {
  source = "./modules/vm"

  vm_name            = "vm-marketing"
  project_label      = "marketing"
  subnet_id          = module.vpc.subnet_id
  cloud_init_content = local.cloud_init_content
  zone               = var.default_zone
  image_family       = var.image_family
  ssh_public_key     = local.ssh_key_content
  preemptible        = true

  security_group_ids = [yandex_vpc_security_group.dev_sg.id]
}

# --- Analytics VM ---
module "analytics_vm" {
  source = "./modules/vm"

  vm_name            = "vm-analytics"
  project_label      = "analytics"
  subnet_id          = module.vpc.subnet_id
  cloud_init_content = local.cloud_init_content
  zone               = var.default_zone
  image_family       = var.image_family
  ssh_public_key     = local.ssh_key_content
  preemptible        = true

  security_group_ids = [yandex_vpc_security_group.dev_sg.id]
}