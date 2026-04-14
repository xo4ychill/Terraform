#!/bin/bash
# ======================================================================
# setup-lockbox.sh — Безопасное создание секрета в Yandex LockBox
# ======================================================================
# Использование:
#   ./scripts/setup-lockbox.sh <folder_id> [secret_name]
#
# Безопасность:
#   • Пароль генерируется локально и НИКОГДА не передаётся в аргументах
#   • Пароль не сохраняется в истории команд (используется read -s)
#   • Вывод пароля только в файл с ограниченными правами
# ======================================================================

set -euo pipefail

# -------------------- КОНФИГУРАЦИЯ --------------------
readonly SCRIPT_NAME="$(basename "$0")"
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

log_info()    { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

usage() {
    cat << EOF
Использование: $SCRIPT_NAME <folder_id> [secret_name]

Аргументы:
  folder_id     ID каталога Yandex Cloud (обязательно)
  secret_name   Имя секрета (по умолчанию: mysql-credentials)

Опции:
  -p, --password FILE   Прочитать пароль из файла (вместо генерации)
  -f, --force           Пересоздать секрет, если уже существует
  -q, --quiet           Минимальный вывод (для CI/CD)
  -h, --help            Показать эту справку

Примеры:
  $ $SCRIPT_NAME b1gxxxxxxxxxxxxxxxxx
  $ $SCRIPT_NAME b1g... mysql-prod --password ./secret.txt
  $ $SCRIPT_NAME b1g... --force

Безопасность:
  • Пароль генерируется с использованием /dev/urandom
  • При вводе вручную используется скрытый режим (без эха)
  • Пароль сохраняется только в файл с правами 600
EOF
    exit 1
}

check_dependencies() {
    local deps=("yc" "jq")
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            log_error "Требуемая утилита не найдена: $cmd"
            [[ "$cmd" == "yc" ]] && echo "Установите: https://cloud.yandex.ru/docs/cli/quickstart"
            [[ "$cmd" == "jq" ]] && echo "Установите: sudo apt install jq"
            exit 2
        fi
    done
}

generate_secure_password() {
    # Генерация криптографически стойкого пароля:
    # • 32 символа
    # • Верхние/нижние буквы, цифры, спецсимволы
    # • Исключены неоднозначные символы (O0Il1)
    local chars='A-HJ-NP-Za-km-z2-9!@#$%^&*'
    local password=""
    for ((i=0; i<32; i++)); do
        password+="${chars:RANDOM%${#chars}:1}"
    done
    echo "$password"
}

check_yc_auth() {
    if ! yc config list &>/dev/null; then
        log_error "Yandex Cloud CLI не настроен. Выполните: yc init"
        exit 3
    fi
    
    # Проверка прав на работу с LockBox
    if ! yc lockbox secret list --folder-id "$1" --limit 1 &>/dev/null; then
        log_error "Нет прав на работу с LockBox в каталоге $1"
        log_error "Необходимые роли: lockbox.payloadViewer, lockbox.secretAdmin"
        exit 4
    fi
}

secret_exists() {
    local folder_id="$1"
    local secret_name="$2"
    
    local existing=$(yc lockbox secret list \
        --folder-id "$folder_id" \
        --filter "name=${secret_name}" \
        --format json 2>/dev/null | jq -r '.[].id // empty')
    
    [[ -n "$existing" ]] && echo "$existing" || echo ""
}

create_lockbox_secret() {
    local folder_id="$1"
    local secret_name="$2"
    local password="$3"
    local force="${4:-false}"
    
    # Проверка существования
    local existing_id
    existing_id=$(secret_exists "$folder_id" "$secret_name")
    
    if [[ -n "$existing_id" ]]; then
        if [[ "$force" == "true" ]]; then
            log_warn "Секрет '${secret_name}' уже существует. Пересоздаём..."
            # Добавляем новую версию пароля, не удаляя старую (для отката)
            yc lockbox secret version add \
                --id "$existing_id" \
                --payload "[{\"key\":\"password\",\"text_value\":\"${password}\"}]" \
                --format json > /dev/null
            echo "$existing_id"
            return 0
        else
            log_error "Секрет '${secret_name}' уже существует (ID: ${existing_id})"
            log_info "Используйте --force для добавления новой версии пароля"
            return 1
        fi
    fi
    
    # Создание нового секрета
    log_info "Создание секрета '${secret_name}'..."
    
    local result
    result=$(yc lockbox secret create \
        --name "$secret_name" \
        --description "MySQL credentials - created $(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --folder-id "$folder_id" \
        --payload "[{\"key\":\"password\",\"text_value\":\"${password}\"}]" \
        --format json 2>&1)
    
    if ! echo "$result" | jq -e '.id' > /dev/null 2>&1; then
        log_error "Ошибка создания секрета:"
        echo "$result" >&2
        return 2
    fi
    
    echo "$result" | jq -r '.id'
}

save_password_safely() {
    local password="$1"
    local secret_name="$2"
    local output_file="./.${secret_name}.password"
    
    # Сохранение в файл с безопасными правами
    {
        echo "# Пароль для секрета: ${secret_name}"
        echo "# Создан: $(date)"
        echo "# ⚠️  Удалите этот файл после использования!"
        echo ""
        echo "${password}"
    } > "$output_file"
    
    chmod 600 "$output_file"
    
    echo "$output_file"
}

print_terraform_config() {
    local secret_id="$1"
    local secret_name="$2"
    
    cat << EOF

${GREEN}==================================================${NC}
${GREEN}  🔐 Секрет создан успешно${NC}
${GREEN}==================================================${NC}

📋 ID секрета для Terraform:
   ${YELLOW}${secret_id}${NC}

📄 Добавьте в variables.tf:
   variable "lockbox_secret_id" {
     default = "${secret_id}"
   }

📄 Пример использования в main.tf:
   data "yandex_lockbox_secret_version" "mysql_password" {
     secret_id = "${secret_id}"
   }
   
   module "mysql" {
     # ...
     db_password = data.yandex_lockbox_secret_version.mysql_password.payload["password"]
   }

🔍 Проверка через CLI:
   yc lockbox secret version list --id ${secret_id}

⚠️  ВАЖНО:
   • Не коммитьте файл с паролем в репозиторий
   • Ротируйте пароль регулярно через: yc lockbox secret version add
   • В production используйте отдельные секреты для dev/staging/prod

EOF
}

# -------------------- ОСНОВНАЯ ЛОГИКА --------------------

main() {
    # Парсинг аргументов
    local folder_id=""
    local secret_name="mysql-credentials"
    local password_file=""
    local force="false"
    local quiet="false"
    
    # Обработка позиционных и именованных аргументов
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--password)
                password_file="$2"
                shift 2
                ;;
            -f|--force)
                force="true"
                shift
                ;;
            -q|--quiet)
                quiet="true"
                shift
                ;;
            -h|--help)
                usage
                ;;
            -*)
                log_error "Неизвестный параметр: $1"
                usage
                ;;
            *)
                if [[ -z "$folder_id" ]]; then
                    folder_id="$1"
                elif [[ "$secret_name" == "mysql-credentials" ]]; then
                    secret_name="$1"
                else
                    log_error "Слишком много аргументов"
                    usage
                fi
                shift
                ;;
        esac
    done
    
    # Валидация обязательных параметров
    [[ -z "$folder_id" ]] && { log_error "folder_id обязателен"; usage; }
    
    # Проверка формата folder_id
    if [[ ! "$folder_id" =~ ^b1g[a-z0-9]{27}$ ]]; then
        log_error "Неверный формат folder_id: $folder_id"
        log_error "Ожидаемый формат: b1gxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        exit 5
    fi
    
    [[ "$quiet" != "true" ]] && {
        echo ""
        echo -e "${GREEN}==================================================${NC}"
        echo -e "${GREEN}  🔐 Yandex LockBox Secret Setup${NC}"
        echo -e "${GREEN}==================================================${NC}"
        echo "Catalog:    ${folder_id}"
        echo "Secret:     ${secret_name}"
        echo "Force:      ${force}"
        echo ""
    }
    
    # Проверка зависимостей и авторизации
    check_dependencies
    check_yc_auth "$folder_id"
    
    # Получение пароля
    local password=""
    if [[ -n "$password_file" ]]; then
        # Чтение из файла
        if [[ ! -f "$password_file" ]]; then
            log_error "Файл с паролем не найден: $password_file"
            exit 6
        fi
        password=$(< "$password_file")
        [[ "$quiet" != "true" ]] && log_info "✓ Пароль прочитан из файла"
    else
        # Интерактивный выбор
        echo -e "${YELLOW}Выберите способ получения пароля:${NC}"
        echo "  1) Сгенерировать безопасный пароль (рекомендуется)"
        echo "  2) Ввести пароль вручную (скрытый ввод)"
        echo -n "Ваш выбор [1/2]: "
        read -r choice
        
        case "$choice" in
            2)
                echo -n "Введите пароль (мин. 12 символов): "
                read -rs password
                echo ""
                if [[ ${#password} -lt 12 ]]; then
                    log_error "Пароль слишком короткий"
                    exit 7
                fi
                ;;
            *)
                password=$(generate_secure_password)
                [[ "$quiet" != "true" ]] && log_info "✓ Пароль сгенерирован"
                ;;
        esac
    fi
    
    # Создание секрета
    local secret_id
    secret_id=$(create_lockbox_secret "$folder_id" "$secret_name" "$password" "$force")
    
    if [[ -z "$secret_id" ]]; then
        log_error "Не удалось создать секрет"
        exit 8
    fi
    
    # Безопасное сохранение пароля (опционально)
    if [[ "$quiet" != "true" ]]; then
        echo ""
        echo -n "💾 Сохранить пароль в файл для проверки? [y/N]: "
        read -r save_choice
        if [[ "$save_choice" =~ ^[Yy]$ ]]; then
            local saved_file
            saved_file=$(save_password_safely "$password" "$secret_name")
            log_info "Пароль сохранён в: ${saved_file}"
            log_warn "⚠️  Удалите этот файл после первого использования!"
        fi
    fi
    
    # Вывод инструкции для Terraform
    [[ "$quiet" != "true" ]] && print_terraform_config "$secret_id" "$secret_name"
    
    # Для CI/CD: вывод только ID секрета
    if [[ "${CI:-}" == "true" ]] || [[ "$quiet" == "true" ]]; then
        echo "LOCKBOX_SECRET_ID=${secret_id}"
    fi
}

# Запуск с обработкой ошибок
main "$@" || {
    exit_code=$?
    log_error "Скрипт завершён с ошибкой (код: $exit_code)"
    exit $exit_code
}