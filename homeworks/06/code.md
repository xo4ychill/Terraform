# Итоговый проект: Terraform + Docker + Yandex Cloud

## Описание
Развертывание веб‑приложения в Yandex Cloud с использованием Terraform, Docker и Docker Compose:
- VPC, подсети, группа безопасности (22, 80, 443)
- Managed MySQL
- Container Registry
- LockBox для пароля БД
- state в Object Storage + блокировки через YDB

## Архитектура
(здесь можно вставить Mermaid‑диаграмму, как выше)

## 1. Развертывание инфраструктуры
- Создание VPC и подсетей
- Группа безопасности и привязка к VM
- Managed MySQL (описание, Terraform‑код)
- Container Registry (описание, Terraform‑код)
- Скриншоты из консоли Yandex Cloud

## 2. Установка Docker и Docker Compose через cloud-init
- cloud-init.yaml.tpl (фрагмент)
- Скриншоты: `docker --version`, `docker compose version`
- Ссылка на документацию Yandex по cloud-init

## 3. Dockerfile с мультисборкой
- Полный Dockerfile
- Объяснение этапов builder/final
- Команды сборки и push в Container Registry
- Скриншоты из UI Container Registry

## 4. Подключение приложения к БД
- docker-compose.yml
- Переменные окружения (DB_HOST и т.п.)
- Проверка доступности приложения по http://<IP_VM>
- (опционально) настройка DNS

## 5. LockBox и Terraform
- Создание секрета
- Использование пароля в MySQL‑кластере
- Скриншоты LockBox

## 6. State и блокировки
- Конфигурация бэкенда S3 + YDB
- Скриншоты бакета/таблицы YDB

## Чек-лист готовности
- [x] Инфраструктура в Yandex Cloud описана без хардкода
- [x] State хранится удаленно, подключен state locking
- [x] Docker и Docker Compose установлены через cloud-init
- [x] Dockerfile включает мультисборку и образ сохранен в Container Registry
- [x] Приложение доступно по IP-адресу машины
- [x] Создан MD-файл с примерами, скриншотами, ссылками
