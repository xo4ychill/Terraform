#cloud-config
# ======================================================================
# Cloud-Init: Установка Docker и Docker Compose + запуск приложения
# ======================================================================

users:
  - name: yc-user
    groups:
      - sudo
      - docker
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_authorized_keys:
      - ${ssh_key}

# --- Обновление пакетов ---
package_update: true

# --- Установка Docker и Docker Compose (Задание 2) ---
packages:
  - apt-transport-https
  - ca-certificates
  - curl
  - gnupg
  - lsb-release
  - git
  - python3-pip

runcmd:
  # ===== ШАГ 1: Добавление GPG-ключа Docker =====
  - |
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

  # ===== ШАГ 2: Добавление репозитория Docker =====
  - |
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

  # ===== ШАГ 3: Установка Docker Engine, CLI, Containerd =====
  - |
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # ===== ШАГ 4: Включение и запуск Docker =====
  - systemctl enable docker
  - systemctl start docker
  - systemctl enable containerd
  - systemctl start containerd

  # ===== ШАГ 5: Проверка установки Docker =====
  - docker --version
  - docker compose version

  # ===== ШАГ 6: Авторизация в Yandex Container Registry =====
  # Для корректной работы push/pull образов
  - |
    cat > /home/yc-user/.docker/config.json << 'DOCKERCFG'
    {
      "credHelpers": {
        "cr.yandex": "yc"
      }
    }
    DOCKERCFG
  - chown yc-user:yc-user /home/yc-user/.docker/config.json

  # ===== ШАГ 7: Создание каталога проекта =====
  - mkdir -p /opt/app
  - chown yc-user:yc-user /opt/app

  # ===== ШАГ 8: Настройка переменных окружения для подключения к MySQL =====
  - |
    cat > /opt/app/.env << ENVEOF
    DB_HOST=${db_host}
    DB_PORT=${db_port}
    DB_NAME=${db_name}
    DB_USER=${db_user}
    DB_PASSWORD=${db_password}
    REGISTRY_URL=${registry_url}
    ENVEOF
  - chmod 600 /opt/app/.env
  - chown yc-user:yc-user /opt/app/.env

  # ===== ШАГ 9: Создание docker-compose.yml =====
  - |
    cat > /opt/app/docker-compose.yml << 'COMPOSEEOF'
    version: "3.9"

    services:
      web:
        image: ${registry_url}/app:latest
        container_name: web-app
        restart: unless-stopped
        ports:
          - "80:80"
        environment:
          - DB_HOST=${DB_HOST}
          - DB_PORT=${DB_PORT}
          - DB_NAME=${DB_NAME}
          - DB_USER=${DB_USER}
          - DB_PASSWORD=${DB_PASSWORD}
        networks:
          - app-network

    networks:
      app-network:
        driver: bridge
    COMPOSEEOF

  # ===== ШАГ 10: Настройка firewall (UFW) =====
  - ufw allow 22/tcp
  - ufw allow 80/tcp
  - ufw allow 443/tcp
  - ufw --force enable

  # ===== ШАГ 11: Лог завершения cloud-init =====
  - echo "CLOUD-INIT COMPLETED SUCCESSFULLY" > /opt/app/cloud-init-done.txt
  - date >> /opt/app/cloud-init-done.txt

# --- Финальное сообщение ---
final_message: "Cloud-init finished! Docker and Docker Compose installed. System is ready for container deployment."
