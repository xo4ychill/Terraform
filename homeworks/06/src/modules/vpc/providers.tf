terraform {
  required_version = ">= 1.12.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.100"
    }
  }
}
# ===== Провайдер Yandex Cloud =====
provider "yandex" {
  # Используем ключ сервисного аккаунта из файла
  # Файл НЕ коммитится в Git (указан в .gitignore)
  service_account_key_file = pathexpand(var.service_account_key_file)
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.default_zone
}
