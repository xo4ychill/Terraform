# Создаём сеть
resource "yandex_vpc_network" "develop" {
  name = var.network_name
}

# Создаём подсеть в указанной зоне
resource "yandex_vpc_subnet" "develop" {
  name           = var.subnet_name
  zone           = var.zone
  network_id     = yandex_vpc_network.develop.id
  v4_cidr_blocks = var.v4_cidr_blocks
}