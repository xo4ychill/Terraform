terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  zone = var.zone
}

# --- сеть ---
resource "yandex_vpc_network" "net" {
  name = "mirror-net"
}

resource "yandex_vpc_subnet" "subnet" {
  zone           = var.zone
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["10.10.0.0/24"]
}

# --- security ---
resource "yandex_vpc_security_group" "sg" {
  network_id = yandex_vpc_network.net.id

  ingress { protocol = "TCP" port = 22  v4_cidr_blocks = ["0.0.0.0/0"] }
  ingress { protocol = "TCP" port = 80  v4_cidr_blocks = ["0.0.0.0/0"] }
  ingress { protocol = "TCP" port = 443 v4_cidr_blocks = ["0.0.0.0/0"] }

  egress { protocol = "ANY" v4_cidr_blocks = ["0.0.0.0/0"] }
}

# --- S3 ---
resource "random_id" "id" {
  byte_length = 4
}

resource "yandex_storage_bucket" "mirror" {
  bucket = "tf-mirror-${random_id.id.hex}"
}

# --- service account ---
resource "yandex_iam_service_account" "sa" {
  name = "mirror-sa"
}

resource "yandex_resourcemanager_folder_iam_member" "s3" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

# --- instance group (HA) ---
resource "yandex_compute_instance_group" "mirror" {
  name               = "tf-mirror-group"
  service_account_id = yandex_iam_service_account.sa.id

  instance_template {
    platform_id = "standard-v3"

    resources {
      cores  = 2
      memory = 2
    }

    boot_disk {
      initialize_params {
        image_id = var.image_id
      }
    }

    network_interface {
      subnet_ids         = [yandex_vpc_subnet.subnet.id]
      nat                = true
      security_group_ids = [yandex_vpc_security_group.sg.id]
    }

    metadata = {
      ssh-keys = "ubuntu:${file(var.ssh_key)}"
    }
  }

  scale_policy {
    auto_scale {
      min_zone_size = 2
      max_size      = 5
      initial_size  = 2
      cpu_utilization_target = 60
    }
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion   = 1
  }
}