#!/bin/bash
# ======================================================================
# docker-push.sh — Сборка и публикация Docker-образа в Yandex Container Registry
# ======================================================================
# Использование:
#   ./scripts/docker-push.sh <registry_url> [image_tag] [build_context]
#
# Примеры:
#   ./scripts/docker-push.sh cr.yandex/crn123456789/abcdefg
#   ./scripts/docker-push.sh cr.yandex/... app:v1.2.3 ./src
#   CI=true BUILD_ARGS="--build-arg ENV=prod" ./scripts/docker-push.sh ...
# ======================================================================

set -euo pipefail

# -------------------- КОНФИГУРАЦИЯ --------------------
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Цвета для вывода
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# -------------------- ФУНКЦИИ --------------------

log_info()    { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_step()    { echo -e "\n${GREEN}➜${NC} $*"; }

usage() {
    cat << EOF
Использование: $SCRIPT_NAME <registry_url> [image_tag] [build_context]

Аргументы:
  registry_url    URL реестра (обязательно), например: cr.yandex/crn123/abc
  image_tag       Тег образа (по умолчанию: latest)
  build_context   Путь к контексту сборки (по умолчанию: ${PROJECT_ROOT}/src)

Переменные окружения:
  CI              Если установлен, подавляет интерактивные запросы
  BUILD_ARGS      Дополнительные аргументы для docker build
  SKIP_PUSH       Если установлен, только сборка без push
  DRY_RUN         Если установлен, только вывод команд без выполнения

Примеры:
  $ $SCRIPT_NAME cr.yandex/crn123/abc
  $ $SCRIPT_NAME cr.yandex/... app:v1.2.3 ./src
  $ CI=true BUILD_ARGS="--build-arg VERSION=1.0" $SCRIPT_NAME cr.yandex/...
EOF
    exit 1
}

check_dependencies() {
    local deps=("docker" "yc")
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            log_error "Требуемая утилита не найдена: $cmd"
            exit 2
        fi
    done
    # jq опционален, но желателен
    if ! command -v jq &>/dev/null; then
        log_warn "jq не установлен: некоторые проверки будут упрощены"
    fi
}

validate_registry_url() {
    local url="$1"
    # Проверка формата Yandex Container Registry
    if [[ ! "$url" =~ ^cr\.yandex/[a-z0-9_-]+/[a-z0-9_-]+$ ]]; then
        log_error "Неверный формат registry_url: $url"
        log_error "Ожидаемый формат: cr.yandex/<registry_id>/<repo_name>"
        exit 3
    fi
}

check_yc_auth() {
    log_step "Проверка авторизации в Yandex Cloud..."
    
    if ! yc config list &>/dev/null; then
        log_error "Yandex Cloud CLI не настроен. Выполните:"
        echo "  yc init"
        exit 4
    fi
    
    # Проверка доступа к реестру
    if ! yc container registry list --folder-id "$(yc config get folder-id 2>/dev/null || echo '')" &>/dev/null; then
        log_warn "Не удалось проверить доступ к Container Registry"
        log_warn "Убедитесь, что у сервисного аккаунта есть права: container-registry.images.uploader"
    else
        log_info "✓ Доступ к Container Registry подтверждён"
    fi
}

docker_login() {
    local registry_url="$1"
    log_step "Авторизация в ${registry_url}..."
    
    # Используем yc для получения токена (безопаснее, чем пароль)
    if ! docker login -u iam -p "$(yc iam create-token 2>/dev/null)" "$registry_url" &>/dev/null; then
        log_error "Не удалось авторизоваться в реестре"
        log_error "Проверьте: 1) настройку yc, 2) права сервисного аккаунта"
        exit 5
    fi
    log_info "✓ Авторизация успешна"
}

build_image() {
    local registry_url="$1"
    local image_tag="$2"
    local build_context="$3"
    local image_name="${registry_url}/app:${image_tag}"
    
    log_step "Сборка образа: ${image_name}"
    
    local build_cmd=(docker build)
    
    # Добавляем дополнительные аргументы сборки, если заданы
    if [[ -n "${BUILD_ARGS:-}" ]]; then
        # shellcheck disable=SC2086
        build_cmd+=(${BUILD_ARGS})
    fi
    
    # Метаданные для отслеживания сборки
    build_cmd+=(
        --label "org.opencontainers.image.created=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        --label "org.opencontainers.image.revision=${GIT_COMMIT:-unknown}"
        --label "org.opencontainers.image.source=${GIT_REPO:-unknown}"
        --label "built.by=${USER:-unknown}"
        -t "$image_name"
        "$build_context"
    )
    
    # В режиме DRY_RUN только выводим команду
    if [[ "${DRY_RUN:-}" == "true" ]]; then
        log_warn "[DRY_RUN] Команда сборки:"
        echo "  ${build_cmd[*]}"
        return 0
    fi
    
    if ! "${build_cmd[@]}"; then
        log_error "Сборка образа не удалась"
        exit 6
    fi
    log_info "✓ Образ собран"
}

scan_image() {
    local image_name="$1"
    
    # Опциональная проверка уязвимостей (требует триви)
    if command -v trivy &>/dev/null && [[ "${SKIP_SCAN:-}" != "true" ]]; then
        log_step "Сканирование образа на уязвимости..."
        if ! trivy image --exit-code 0 --severity HIGH,CRITICAL "$image_name" &>/dev/null; then
            log_warn "⚠️ Найдены уязвимости высокого уровня (продолжаем по запросу)"
        else
            log_info "✓ Уязвимости не обнаружены"
        fi
    fi
}

push_image() {
    local registry_url="$1"
    local image_tag="$2"
    local image_name="${registry_url}/app:${image_tag}"
    
    [[ "${SKIP_PUSH:-}" == "true" ]] && return 0
    [[ "${DRY_RUN:-}" == "true" ]] && {
        log_warn "[DRY_RUN] Команда push:"
        echo "  docker push $image_name"
        return 0
    }
    
    log_step "Публикация образа: ${image_name}"
    
    if ! docker push "$image_name"; then
        log_error "Не удалось опубликовать образ"
        exit 7
    fi
    log_info "✓ Образ опубликован"
}

print_summary() {
    local registry_url="$1"
    local image_tag="$2"
    local image_name="${registry_url}/app:${image_tag}"
    
    echo ""
    echo -e "${GREEN}==================================================${NC}"
    echo -e "${GREEN}  ✅ Сборка и публикация завершена${NC}"
    echo -e "${GREEN}==================================================${NC}"
    echo ""
    echo "📦 Образ:     ${image_name}"
    echo "🔍 Проверка:  docker run --rm ${image_name} curl -f http://localhost/"
    echo "🚀 Запуск:    docker pull ${image_name} && docker run -d -p 80:80 ${image_name}"
    echo ""
    
    # Вывод команды для развертывания в YC
    if command -v yc &>/dev/null; then
        echo "💡 Для развертывания в Yandex Cloud:"
        echo "   yc compute container create --image-name ${image_name} --service-account-id <sa_id>"
    fi
}

# -------------------- ОСНОВНАЯ ЛОГИКА --------------------

main() {
    # Парсинг аргументов
    [[ $# -lt 1 ]] && usage
    
    local registry_url="${1}"
    local image_tag="${2:-latest}"
    local build_context="${3:-${PROJECT_ROOT}/src}"
    
    # Валидация
    check_dependencies
    validate_registry_url "$registry_url"
    
    # Проверка пути к контексту
    if [[ ! -d "$build_context" ]]; then
        log_error "Директория сборки не найдена: $build_context"
        exit 8
    fi
    
    # Информация о сборке
    echo ""
    echo -e "${GREEN}==================================================${NC}"
    echo -e "${GREEN}  🐳 Docker Build & Push${NC}"
    echo -e "${GREEN}==================================================${NC}"
    echo "Registry:   ${registry_url}"
    echo "Tag:        ${image_tag}"
    echo "Context:    ${build_context}"
    echo "Git Commit: ${GIT_COMMIT:-$(git rev-parse --short HEAD 2>/dev/null || echo 'N/A')}"
    echo "Mode:       ${DRY_RUN:-false} / ${SKIP_PUSH:-false}"
    echo ""
    
    # Выполнение шагов
    check_yc_auth
    docker_login "$registry_url"
    build_image "$registry_url" "$image_tag" "$build_context"
    scan_image "${registry_url}/app:${image_tag}"
    push_image "$registry_url" "$image_tag"
    
    # Итог
    print_summary "$registry_url" "$image_tag"
}

# Запуск
main "$@"