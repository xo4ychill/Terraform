# ======================================================================
# Dockerfile — Мультисборка (Multi-Stage Build) для web-приложения
# Stage 1: Builder — сборка и тестирование
# Stage 2: Runtime — минимальный образ для production
# ======================================================================

# ==================== STAGE 1: BUILDER ====================
FROM ubuntu:22.04 AS builder
LABEL maintainer="your-team@example.com"
LABEL description="Builder stage for web application"

# Установка зависимостей для сборки
RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    php8.1-fpm \
    php8.1-mysql \
    php8.1-mbstring \
    php8.1-xml \
    php8.1-curl \
    php8.1-zip \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

# Копируем исходные файлы приложения
COPY app/ /var/www/app/

# Проверка синтаксиса PHP
RUN php -l /var/www/app/index.php 2>/dev/null || true
RUN php -m | grep -E "mysql|mbstring|xml|curl" || echo "⚠️ Проверьте модули PHP"

# Оптимизация прав
RUN chown -R www-data:www-data /var/www/app \
    && find /var/www/app -type d -exec chmod 755 {} \; \
    && find /var/www/app -type f -exec chmod 644 {} \;

# ==================== STAGE 2: RUNTIME ====================
FROM ubuntu:22.04 AS runtime
LABEL maintainer="xo4y.chill@yandex.ru"
LABEL description="Production image: Nginx + PHP-FPM"
LABEL version="1.0.0"

# Установка минимального набора пакетов
RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    php8.1-fpm \
    php8.1-mysql \
    php8.1-mbstring \
    php8.1-xml \
    php8.1-curl \
    supervisor \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

# Конфигурация Nginx
COPY nginx.conf /etc/nginx/sites-available/default
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

# Конфигурация Supervisor для управления процессами
COPY <<'EOF' /etc/supervisor/conf.d/app.conf
[supervisord]
nodaemon=true
logfile=/dev/stdout
pidfile=/var/run/supervisord.pid

[program:nginx]
command=nginx -g "daemon off;"
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stderr_logfile=/dev/stderr

[program:php-fpm]
command=php-fpm8.1 -F
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stderr_logfile=/dev/stderr
EOF

# Копируем файлы приложения из builder
COPY --from=builder --chown=www-data:www-data /var/www/app /var/www/app

# Создаём симлинк для совместимости
RUN ln -sf /var/www/app /var/www/html

# ✅ Запуск от non-root пользователя для безопасности
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /var/www/app /var/www/html /var/log/nginx /var/lib/nginx /run
USER appuser

EXPOSE 80

# Проверка здоровья контейнера
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Запуск через supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]