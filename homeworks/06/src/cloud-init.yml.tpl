#cloud-config
# ======================================================================
# Cloud-Init: Установка Docker, настройка приложения, интеграция с LockBox
# ======================================================================

users:
  - name: yc-user
    groups: sudo, docker
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_authorized_keys:
      - ${ssh_key}

package_update: true
packages:
  - curl
  - jq
  - git
  - apt-transport-https
  - ca-certificates
  - gnupg
  - lsb-release

runcmd:
  # ===== ШАГ 1: Установка Docker =====
  - |
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    systemctl enable --now docker containerd

  # ===== ШАГ 2: Установка YC CLI для работы с LockBox =====
  - |
    if [ "${use_lockbox}" = "true" ]; then
      curl -L https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash -s -- -n
      echo 'export PATH="$HOME/bin:$PATH"' >> /home/yc-user/.bashrc
    fi

  # ===== ШАГ 3: Настройка Docker для Yandex Container Registry =====
  - |
    mkdir -p /home/yc-user/.docker
    cat > /home/yc-user/.docker/config.json << 'EOF'
    {
      "credHelpers": {
        "cr.yandex": "yc"
      }
    }
    EOF
    chown -R yc-user:yc-user /home/yc-user/.docker

  # ===== ШАГ 4: Создание каталога приложения =====
  - mkdir -p /opt/app
  - chown yc-user:yc-user /opt/app

  # ===== ШАГ 5: Создание .env с переменными окружения =====
  - |
    cat > /opt/app/.env << ENVEOF
    DB_HOST=${db_host}
    DB_PORT=${db_port}
    DB_NAME=${db_name}
    DB_USER=${db_user}
    REGISTRY_URL=${registry_url}
    USE_LOCKBOX=${use_lockbox}
    LOCKBOX_SECRET_ID=${lockbox_secret_id}
    ENVIRONMENT=${environment}
    ENVEOF
    chmod 600 /opt/app/.env
    chown yc-user:yc-user /opt/app/.env

  # ===== ШАГ 6: Скрипт запуска приложения с получением пароля из LockBox =====
  - |
    cat > /opt/app/start-app.sh << 'SCRIPTEOF'
    #!/bin/bash
    set -e
    cd /opt/app
    
    # Если используется LockBox — получаем пароль
    if [ "${USE_LOCKBOX}" = "true" ] && [ -n "${LOCKBOX_SECRET_ID}" ]; then
      echo "Получение пароля из LockBox..."
      export DB_PASSWORD=$(yc lockbox payload get --id "${LOCKBOX_SECRET_ID}" --key password --format json 2>/dev/null | jq -r '.value // empty')
      if [ -z "${DB_PASSWORD}" ]; then
        echo "❌ Ошибка: не удалось получить пароль из LockBox"
        exit 1
      fi
    fi
    
    # Запускаем приложение через docker compose
    docker compose up -d
    echo "✅ Приложение запущено"
    SCRIPTEOF
    chmod +x /opt/app/start-app.sh
    chown yc-user:yc-user /opt/app/start-app.sh

  # ===== ШАГ 7: Создание docker-compose.yml =====
  - |
    cat > /opt/app/docker-compose.yml << 'COMPOSEEOF'
    version: "3.9"
    services:
      web:
        image: ${REGISTRY_URL}/app:latest
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
        healthcheck:
          test: ["CMD", "curl", "-f", "http://localhost/"]
          interval: 30s
          timeout: 5s
          retries: 3
          start_period: 10s
    
    networks:
      app-network:
        driver: bridge
    COMPOSEEOF
    chown yc-user:yc-user /opt/app/docker-compose.yml

  # ===== ШАГ 8: Настройка firewall (UFW) =====
  - ufw allow 22/tcp
  - ufw allow 80/tcp
  - ufw allow 443/tcp
  - ufw --force enable

  # ===== ШАГ 9: Автозапуск приложения при старте ВМ =====
  - |
    cat > /etc/systemd/system/app.service << 'SYSTEMDEOF'
    [Unit]
    Description=Application Docker Compose Service
    After=docker.service network-online.target
    Requires=docker.service
    
    [Service]
    Type=oneshot
    RemainAfterExit=yes
    User=yc-user
    WorkingDirectory=/opt/app
    EnvironmentFile=/opt/app/.env
    ExecStart=/opt/app/start-app.sh
    ExecStop=/usr/bin/docker compose down
    
    [Install]
    WantedBy=multi-user.target
    SYSTEMDEOF
    systemctl daemon-reload
    systemctl enable app.service

  # ===== ШАГ 10: Финальная проверка и логирование =====
  - |
    echo "✅ Cloud-init completed at $(date)" > /opt/app/cloud-init.log
    echo "VM: $(hostname), IP: $(hostname -I | awk '{print $1}')" >> /opt/app/cloud-init.log
    docker --version >> /opt/app/cloud-init.log
    docker compose version >> /opt/app/cloud-init.log

final_message: "🎉 Cloud-init finished! Application ready at http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"