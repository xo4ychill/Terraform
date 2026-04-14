# ======================================================================
# providers.tf — Настройка Terraform и провайдера Yandex Cloud
# ======================================================================

terraform {
  # Требуемая версия Terraform (поддержка новых функций)
  required_version = ">= 1.12.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      # ✅ Используем актуальную версию провайдера
      version = ">= 0.120.0"
    }
  }

  # ===== REMOTE STATE в Yandex Object Storage =====
  # State хранится удалённо, блокировка — через DynamoDB-совместимый API
  backend "s3" {
    # Имя бакета (создаётся заранее через yc storage bucket create)
    # yc storage bucket create --name tf.state-bucket --default-storage-class standard --public-read=false
    bucket = "tf.state-bucket"
    
    # Путь к state-файлу: поддерживаем workspaces для окружений
    key = "${terraform.workspace}/terraform.tfstate"
    
    # Регион хранения
    region = "ru-central1"
    
    # ✅ Блокировка через DynamoDB-совместимый эндпоинт
    # Таблица должна быть создана заранее:
    #   yc ydb database serverless create --name tf.state-locks
    dynamodb_table = "tf.state-locks"
    
    # Эндпоинты Yandex Cloud (S3 + DynamoDB совместимые)
    endpoints = {
      s3       = "https://storage.yandexcloud.net"
      dynamodb = "https://ydb.serverless.yandexcloud.net"
    }
    
    # Оптимизации для Yandex Cloud (отключаем лишние проверки)
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    force_path_style            = true
    
    # Шифрование state-файла на стороне сервера
    server_side_encryption = true
  }
}

# ===== Провайдер Yandex Cloud =====
provider "yandex" {
  # Ключ сервисного аккаунта из файла (НЕ коммитить в Git!)
  service_account_key_file = pathexpand(var.service_account_key_file)
  
  # Идентификаторы облака и каталога из переменных
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  
  # Зона по умолчанию для ресурсов
  zone = var.default_zone
}