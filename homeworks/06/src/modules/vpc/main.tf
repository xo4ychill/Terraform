resource "yandex_vpc_network" "network" {
  name = var.network_name
  
  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "yandex_vpc_subnet" "subnet" {
  name           = var.subnet_name
  zone           = var.zone
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = var.v4_cidr_blocks
  
  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}