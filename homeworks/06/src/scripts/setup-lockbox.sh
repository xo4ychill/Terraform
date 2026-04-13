#!/bin/bash
# ======================================================================
# Скрипт создания секрета в Yandex LockBox для пароля MySQL
# ======================================================================
set -euo pipefail

FOLDER_ID="${1:?Использование: $0 <folder_id>}"
SECRET_NAME="${2:-mysql-credentials}"
DB_PASSWORD="${3:-$(openssl rand -base64 24)}"

echo "=================================================="
echo "  Создание секрета в Yandex LockBox"
echo "=================================================="
echo "Catalog:   ${FOLDER_ID}"
echo "Secret:    ${SECRET_NAME}"
echo "Password:  ${DB_PASSWORD:0:4}... (скрыто)"
echo ""

# Создание секрета
SECRET_ID=$(yc lockbox secret create \
    --name "${SECRET_NAME}" \
    --description "MySQL credentials for application" \
    --folder-id "${FOLDER_ID}" \
    --payload "[{\"key\":\"password\",\"text_value\":\"${DB_PASSWORD}\"}]" \
    --format json | jq -r '.id')

echo "✅ Секрет создан: ${SECRET_ID}"
echo ""
echo "Для получения пароля в Terraform используйте:"
echo "  data \"yandex_lockbox_secret_version\" \"mysql_password\" {"
echo "    secret_id = \"${SECRET_ID}\""
echo "  }"
echo ""
echo "Пароль для terraform.tfvars:"
echo "  mysql_password = \"${DB_PASSWORD}\""
