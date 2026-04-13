#!/bin/bash
# ======================================================================
# Скрипт сборки Docker-образа и push в Yandex Container Registry
# ======================================================================
set -euo pipefail

# Конфигурация (передаются через terraform output)
REGISTRY_URL="${1:?Использование: $0 <registry_url>}"
IMAGE_TAG="${2:-latest}"
SOURCE_DIR="$(cd "$(dirname "$0")/.." && pwd)/src"

echo "=================================================="
echo "  Сборка и пуш Docker-образа"
echo "=================================================="
echo "Registry: ${REGISTRY_URL}"
echo "Tag:      ${IMAGE_TAG}"
echo "Source:   ${SOURCE_DIR}"
echo ""

# Шаг 1: Сборка образа
echo "📦 [1/3] Сборка Docker-образа..."
cd "${SOURCE_DIR}"
docker build -t "${REGISTRY_URL}/app:${IMAGE_TAG}" .

# Шаг 2: Проверка образа
echo "🔍 [2/3] Проверка образа..."
docker images "${REGISTRY_URL}/app:${IMAGE_TAG}"

# Шаг 3: Push в Container Registry
echo "🚀 [3/3] Push в Container Registry..."
docker push "${REGISTRY_URL}/app:${IMAGE_TAG}"

echo ""
echo "✅ Образ успешно отправлен: ${REGISTRY_URL}/app:${IMAGE_TAG}"
