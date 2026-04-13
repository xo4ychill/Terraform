terraform {
  required_version = ">= 1.12.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.100"
    }
  }

  # ===== REMOTE STATE в Yandex Object Storage с блокировками =====
  # State хранится удалённо в S3-совместимом хранилище
  # Блокировка осуществляется через DynamoDB-совместимый API Yandex Lockbox
  # (используем use_lockfile = true для встроенной блокировки)
  backend "s3" {
    # Имя бакета для хранения state-файлов
    # Создаётся заранее через YC CLI:
    #   yc storage bucket create --name tf-state-bucket --default-storage-class standard
    bucket = "tf.state-bucket"

    # Путь к state-файлу внутри бакета
    key = "prod/terraform.tfstate"

    # Регион Yandex Cloud
    region = "ru-central1"

    # Включение встроенной блокировки state-файла
    # Terraform создаёт .lock-файл в том же бакете
    # Предотвращает одновременный запуск terraform apply
    use_lockfile = true

    # Эндпоинты Yandex Cloud Storage (S3-совместимый)
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }

    skip_region_validation        = true
    skip_credentials_validation   = true
    skip_requesting_account_id    = true
    skip_s3_checksum              = true
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
