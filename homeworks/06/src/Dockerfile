# ======================================================================
# Dockerfile — Мультисборка (Multi-Stage Build) для web-приложения
# Stage 1: Builder — сборка статических файлов и PHP
# Stage 2: Runtime — финальный образ с nginx + php-fpm
# ======================================================================

# ==================== STAGE 1: BUILDER ====================
FROM ubuntu:22.04 AS builder

LABEL maintainer="student@example.com"
LABEL description="Multi-stage build for web application"
LABEL stage="builder"

# Установка зависимостей для сборки
RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    php8.1-fpm \
    php8.1-mysql \
    php8.1-mbstring \
    php8.1-xml \
    php8.1-curl \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Копируем исходные файлы приложения
COPY app/ /var/www/app/

# Устанавливаем права на файлы
RUN chown -R www-data:www-data /var/www/app \
    && chmod -R 755 /var/www/app

# Создаём тестовую конфигурацию для проверки сборки
RUN php -v
RUN php -m | grep -E "mysql|mbstring|xml|curl"

# ==================== STAGE 2: RUNTIME ====================
FROM ubuntu:22.04 AS runtime

LABEL maintainer="student@example.com"
LABEL description="Web application with Nginx + PHP-FPM"
LABEL version="1.0"

# Установка минимального набора пакетов для runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    php8.1-fpm \
    php8.1-mysql \
    php8.1-mbstring \
    php8.1-xml \
    php8.1-curl \
    supervisor \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Копируем конфигурацию nginx
COPY nginx.conf /etc/nginx/sites-available/default

# Копируем конфигурацию supervisor для управления процессами
RUN mkdir -p /var/log/supervisor
COPY <<'EOF' /etc/supervisor/conf.d/app.conf
[supervisord]
nodaemon=true
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid

[program:nginx]
command=nginx -g "daemon off;"
autostart=true
autorestart=true
stdout_logfile=/var/log/supervisor/nginx-stdout.log
stderr_logfile=/var/log/supervisor/nginx-stderr.log

[program:php-fpm]
command=php-fpm8.1 -F
autostart=true
autorestart=true
stdout_logfile=/var/log/supervisor/php-fpm-stdout.log
stderr_logfile=/var/log/supervisor/php-fpm-stderr.log
EOF

# Копируем файлы приложения из builder stage
COPY --from=builder /var/www/app /var/www/app

# Настраиваем nginx root
RUN ln -sf /var/www/app /var/www/html

# Устанавливаем права
RUN chown -R www-data:www-data /var/www/app /var/www/html

# Открываем порт 80
EXPOSE 80

# Проверка здоровья контейнера (Healthcheck)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Запуск через supervisor (nginx + php-fpm)
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]


Пояснение
Stage	Назначение	Размер результата
builder	Установка всех build-зависимостей, компиляция	Не входит в финальный образ
runtime	Только runtime-зависимости + скопированные артефакты	~150 MB (вместо ~300+ MB без мультисборки)
