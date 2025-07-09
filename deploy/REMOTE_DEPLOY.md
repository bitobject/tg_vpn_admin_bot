# Remote Deployment Guide

Этот документ описывает процесс деплоя Telegram Admin API на удаленный сервер.

## Архитектура деплоя

1. **Локальная сборка** - Docker образы собираются локально
2. **Передача файлов** - Образы и конфигурация передаются на сервер через SSH
3. **Запуск на сервере** - Сервисы запускаются на удаленном сервере

## Требования

### Локально
- Docker и Docker Compose
- SSH доступ к серверу
- Настроенный SSH конфиг

### На сервере
- Docker и Docker Compose
- Открытые порты 80 и 443
- Домен, указывающий на сервер

## Быстрый старт

### 1. Проверка конфигурации
```bash
make check-config
```

### 2. Сборка и деплой
```bash
# Деплой на vps сервер (по умолчанию)
make deploy

# Или на конкретный сервер
make deploy-vps
```

### 3. Проверка статуса
```bash
make status
```

## Доступные команды

### Основные команды
```bash
make build          # Собрать Docker образы
make deploy         # Деплой на vps сервер
make deploy-vps     # Деплой на vps сервер
make build-deploy   # Сборка и деплой в одном команде
```

### Управление сервисами
```bash
make status         # Показать статус сервисов
make logs           # Показать логи
make restart        # Перезапустить сервисы
make stop           # Остановить сервисы
make start          # Запустить сервисы
```

### Утилиты
```bash
make check-config   # Проверить конфигурацию
make clean          # Очистить артефакты сборки
make help           # Показать справку
```

## Ручной деплой

Если нужно больше контроля, можно использовать скрипты напрямую:

### 1. Сборка образов
```bash
./scripts/build.sh
```

### 2. Деплой на сервер
```bash
# На vps сервер
./scripts/deploy-remote.sh vps



# С указанием пути
./scripts/deploy-remote.sh vps /custom/path
```

## Структура файлов на сервере

После деплоя на сервере создается структура:
```
/opt/telegram-admin-api/
├── docker-compose.yml      # Конфигурация Docker Compose
├── env_file               # Переменные окружения
├── images/                # Docker образы
│   ├── app.tar.gz
│   └── nginx.tar.gz
├── nginx/                 # Конфигурация Nginx
├── scripts/               # Скрипты управления
├── certbot/               # SSL сертификаты (автосоздание)
└── logs/                  # Логи (автосоздание)
```

## Мониторинг и логирование

### Проверка статуса
```bash
# Локально
make status

# Напрямую на сервере
ssh vps "cd /opt/telegram-admin-api && docker-compose ps"
```

### Просмотр логов
```bash
# Локально
make logs

# Напрямую на сервере
ssh vps "cd /opt/telegram-admin-api && docker-compose logs -f app"
ssh vps "cd /opt/telegram-admin-api && docker-compose logs -f nginx"
```

### Проверка сертификатов
```bash
ssh vps "cd /opt/telegram-admin-api && ./scripts/check-certs.sh"
```

## Troubleshooting

### Проблемы с SSH
```bash
# Проверка подключения
ssh vps "echo 'Connection successful'"

# Проверка Docker на сервере
ssh vps "docker --version && docker-compose --version"
```

### Проблемы с образами
```bash
# Пересборка образов
make clean
make build

# Проверка размера образов
ls -lh images/*.tar.gz
```

### Проблемы с сервисами
```bash
# Проверка логов
make logs

# Перезапуск сервисов
make restart

# Полная перезагрузка
make stop
make start
```

## Обновление приложения

### Полное обновление
```bash
make build-deploy
```

### Только код (без пересборки образов)
```bash
# Остановить сервисы
make stop

# Передать новые файлы
scp -r ../apps/ vps:/opt/telegram-admin-api/

# Запустить сервисы
make start
```

## Безопасность

- Все секреты хранятся в `env_file`
- SSH ключи для доступа к серверу
- SSL сертификаты Let's Encrypt
- Rate limiting в Nginx
- Строгие заголовки безопасности

## Резервное копирование

### База данных
```bash
# Создание бэкапа
ssh vps "cd /opt/telegram-admin-api && docker-compose exec postgres pg_dump -U \$DB_USERNAME \$DB_NAME > backup_\$(date +%Y%m%d_%H%M%S).sql"

# Восстановление
ssh vps "cd /opt/telegram-admin-api && docker-compose exec -T postgres psql -U \$DB_USERNAME \$DB_NAME < backup_file.sql"
```

### Конфигурация
```bash
# Копирование конфигурации
scp -r vps:/opt/telegram-admin-api/ backup_$(date +%Y%m%d_%H%M%S)/
``` 