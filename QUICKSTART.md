# Быстрый старт - Telegram Admin API

## Предварительные требования

1. **Docker и Docker Compose** установлены на сервере
2. **Домен** `body-architect.ru` указывает на ваш сервер
3. **Порты 80 и 443** открыты на сервере

## Пошаговая настройка

### 1. Клонирование и настройка

```bash
# Перейти в папку deploy
cd deploy

# Запустить полную настройку
./scripts/setup.sh
```

### 2. Настройка переменных окружения

Если скрипт setup.sh попросит настроить переменные, отредактируйте файл `.env`:

```bash
# Database Configuration
DB_NAME=telegram_admin_api_prod
DB_USERNAME=postgres
DB_PASSWORD=your_secure_password_here

# Application Configuration
HOST=body-architect.ru
SECRET_KEY_BASE=auto_generated
GUARDIAN_SECRET_KEY=auto_generated
POOL_SIZE=10

# Let's Encrypt Configuration
CERTBOT_EMAIL=your_email@example.com
```

### 3. Повторный запуск

После настройки переменных:

```bash
./scripts/setup.sh
```

## Проверка работы

После успешного деплоя:

- **Приложение**: https://body-architect.ru
- **API документация**: https://body-architect.ru/api/docs
- **Health check**: https://body-architect.ru/health

## Полезные команды

```bash
# Просмотр логов
docker-compose logs -f

# Проверка сертификатов
./scripts/check-certs.sh

# Обновление сертификатов
./scripts/renew-certs.sh

# Остановка сервисов
docker-compose down

# Перезапуск сервисов
docker-compose restart
```

## Структура файлов

```
deploy/
├── docker-compose.yml          # Конфигурация Docker Compose
├── Dockerfile                  # Образ приложения
├── .env                        # Переменные окружения
├── scripts/                    # Скрипты автоматизации
├── nginx/                      # Конфигурация Nginx
├── certbot/                    # SSL сертификаты (автосоздание)
└── logs/                       # Логи (автосоздание)
```

## Безопасность

- ✅ SSL сертификаты Let's Encrypt
- ✅ Автоматическое обновление сертификатов
- ✅ Rate limiting для API
- ✅ Строгие заголовки безопасности
- ✅ HSTS включен

## Поддержка

При проблемах:
1. Проверьте логи: `docker-compose logs -f`
2. Проверьте статус: `docker-compose ps`
3. Проверьте сертификаты: `./scripts/check-certs.sh` 