# Telegram Admin API - Deployment Guide

Этот проект настроен для деплоя через Docker Compose с Nginx и автоматическим SSL через Let's Encrypt.

## Архитектура

- **Nginx**: Обратный прокси с SSL терминацией
- **Elixir App**: Основное приложение на Phoenix
- **PostgreSQL**: База данных
- **Certbot**: Автоматическое управление SSL сертификатами

## Требования

- Docker и Docker Compose
- Домен, указывающий на сервер (body-architect.ru)
- Открытые порты 80 и 443

## Быстрый старт

### 1. Настройка переменных окружения

```bash
cd deploy
cp env.example .env
```

Отредактируйте `.env` файл:

```bash
# Database Configuration
DB_NAME=telegram_admin_api_prod
DB_USERNAME=postgres
DB_PASSWORD=your_secure_password_here

# Application Configuration
HOST=body-architect.ru
SECRET_KEY_BASE=your_secret_key_base_here
GUARDIAN_SECRET_KEY=your_guardian_secret_key_here
POOL_SIZE=10

# Let's Encrypt Configuration
CERTBOT_EMAIL=your_email@example.com
```

### 2. Генерация секретных ключей

```bash
# Автоматическая генерация всех секретных ключей
./scripts/generate-secrets.sh
```

### 3. Деплой

```bash
# Сделать скрипты исполняемыми
chmod +x scripts/*.sh

# Запустить деплой
./scripts/deploy.sh
```

## Структура файлов

```
deploy/
├── docker-compose.yml          # Основная конфигурация Docker Compose
├── Dockerfile                  # Образ для Elixir приложения
├── .env                        # Переменные окружения (создать из env.example)
├── env.example                 # Пример переменных окружения
├── nginx/
│   ├── nginx.conf             # Основная конфигурация Nginx
│   └── conf.d/
│       └── default.conf       # Конфигурация виртуального хоста
├── scripts/
│   ├── deploy.sh              # Основной скрипт деплоя
│   ├── init-letsencrypt.sh    # Инициализация SSL сертификатов
│   └── renew-certs.sh         # Обновление сертификатов
├── certbot/                   # Сертификаты Let's Encrypt (создается автоматически)
│   ├── conf/
│   └── www/
└── postgres/                  # Инициализация базы данных
    └── init/
```

## Управление сервисами

### Запуск всех сервисов
```bash
docker-compose up -d
```

### Остановка всех сервисов
```bash
docker-compose down
```

### Просмотр логов
```bash
# Все сервисы
docker-compose logs -f

# Конкретный сервис
docker-compose logs -f app
docker-compose logs -f nginx
docker-compose logs -f postgres
```

### Перезапуск сервиса
```bash
docker-compose restart app
```

## SSL сертификаты

### Первоначальная настройка
```bash
./scripts/init-letsencrypt.sh body-architect.ru
```

### Автоматическое обновление
Сертификаты обновляются автоматически каждые 6 часов через Nginx.

Для ручного обновления:
```bash
./scripts/renew-certs.sh
```

### Настройка cron для автоматического обновления
```bash
# Добавить в crontab (crontab -e)
0 12 * * * cd /path/to/deploy && ./scripts/renew-certs.sh >> logs/cert-renewal.log 2>&1
```

## Мониторинг и логирование

### Health checks
- **Nginx**: `http://localhost/health`
- **App**: `https://body-architect.ru/health`
- **Database**: Встроенная проверка в Docker Compose

### Проверка конфигурации
```bash
# Проверка всех переменных окружения
./scripts/check-config.sh
```

### Логи
Логи сохраняются в:
- `logs/` - Логи приложения
- Docker volumes для контейнеров

### Мониторинг сертификатов
```bash
# Проверка статуса сертификатов
docker-compose run --rm certbot certificates

# Проверка срока действия
docker-compose run --rm certbot certificates | grep -A 2 "VALID"

# Подробная проверка сертификатов
./scripts/check-certs.sh
```

## Безопасность

### Настройки Nginx
- Rate limiting для API endpoints
- Строгие заголовки безопасности
- HSTS включен
- Современные SSL шифры

### Переменные окружения
- Все секреты хранятся в `.env` файле
- Файл `.env` добавлен в `.gitignore`
- Используются безопасные пароли

### Обновления
```bash
# Обновление приложения
git pull
docker-compose build --no-cache app
docker-compose up -d app

# Обновление всех сервисов
docker-compose pull
docker-compose up -d
```

## Резервное копирование

### База данных
```bash
# Создание бэкапа
docker-compose exec postgres pg_dump -U $DB_USERNAME $DB_NAME > backup_$(date +%Y%m%d_%H%M%S).sql

# Восстановление
docker-compose exec -T postgres psql -U $DB_USERNAME $DB_NAME < backup_file.sql
```

### Сертификаты
```bash
# Копирование сертификатов
cp -r certbot/conf backup_certs_$(date +%Y%m%d_%H%M%S)/
```

## Troubleshooting

### Проблемы с SSL
```bash
# Проверка сертификатов
docker-compose run --rm certbot certificates

# Принудительное обновление
docker-compose run --rm certbot renew --force-renewal
```

### Проблемы с приложением
```bash
# Проверка логов
docker-compose logs app

# Перезапуск приложения
docker-compose restart app

# Проверка переменных окружения
docker-compose exec app env | grep -E "(DB_|HOST|SECRET)"
```

### Проблемы с базой данных
```bash
# Проверка подключения
docker-compose exec postgres pg_isready -U $DB_USERNAME

# Проверка логов
docker-compose logs postgres
```

## Производительность

### Настройки Nginx
- Gzip сжатие включено
- HTTP/2 поддержка
- Кэширование статических файлов
- Rate limiting для защиты от DDoS

### Настройки приложения
- Connection pooling для базы данных
- Оптимизированные настройки Phoenix
- Health checks для всех сервисов

## Поддержка

При возникновении проблем:
1. Проверьте логи: `docker-compose logs -f`
2. Проверьте статус сервисов: `docker-compose ps`
3. Проверьте health checks
4. Убедитесь, что все переменные окружения настроены правильно 