# Telegram Admin API

REST API для управления Telegram ботом с JWT аутентификацией и PostgreSQL.

## Архитектура

Проект построен как umbrella приложение с следующими компонентами:

- **admin_api** - REST API с Phoenix
- **core** - Бизнес-логика и схемы данных
- **shared** - Общие утилиты
- **telegram_api** - Интеграция с Telegram API

## Требования

- Elixir 1.16+
- Erlang/OTP 25+
- PostgreSQL 12+
- Node.js 18+ (для assets)

## Установка

1. Клонируйте репозиторий:
```bash
git clone <repository-url>
cd telegram-admin-api
```

2. Установите зависимости:
```bash
mix deps.get
```

3. Настройте базу данных:
```bash
# Создайте базу данных
createdb telegram_admin_api_dev

# Запустите миграции
mix ecto.migrate

# Создайте seed данные (первый админ)
mix run apps/core/priv/repo/seeds.exs
```

4. Настройте переменные окружения:
```bash
export DB_USERNAME=postgres
export DB_PASSWORD=postgres
export DB_HOST=localhost
export DB_NAME=telegram_admin_api_dev
export GUARDIAN_SECRET_KEY="your-secret-key-here"
```

5. Запустите сервер:
```bash
mix phx.server
```

API будет доступен по адресу: http://localhost:4000

## API Endpoints

### Аутентификация

#### POST /api/v1/auth/login
Вход в систему с логином/паролем.

**Request:**
```json
{
  "login": "admin@example.com",
  "password": "admin123"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "admin": {
    "id": "uuid",
    "email": "admin@example.com",
    "username": "admin",
    "role": "admin"
  }
}
```

#### POST /api/v1/auth/refresh
Обновление JWT токена.

**Request:**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### GET /api/v1/auth/me
Получение профиля текущего администратора.

**Headers:**
```
Authorization: Bearer <token>
```

#### POST /api/v1/auth/logout
Выход из системы.

**Headers:**
```
Authorization: Bearer <token>
```

### Управление администраторами (только для админов)

#### GET /api/v1/admins
Список всех администраторов.

#### POST /api/v1/admins
Создание нового администратора.

**Request:**
```json
{
  "admin": {
    "email": "admin2@example.com",
    "username": "admin2",
    "password": "password123",
    "password_confirmation": "password123",
    "role": "admin"
  }
}
```

#### GET /api/v1/admins/:id
Получение администратора по ID.

#### PUT /api/v1/admins/:id
Обновление администратора.

#### DELETE /api/v1/admins/:id
Удаление администратора.

#### PUT /api/v1/admins/:id/password
Обновление пароля администратора.

**Request:**
```json
{
  "password": {
    "password": "newpassword123",
    "password_confirmation": "newpassword123"
  }
}
```

### Системные endpoints

#### GET /api/v1/health
Проверка состояния API.

## Безопасность

### JWT Токены
- Access token: 1 день
- Refresh token: 30 дней
- Автоматическое обновление токенов

### Rate Limiting
- 100 запросов в минуту на IP
- Настраивается в конфигурации

### Роли администраторов
- **admin** - полный доступ ко всем функциям

### Хеширование паролей
- bcrypt с cost factor 12
- Автоматическое хеширование при создании/обновлении

## Разработка

### Запуск в development режиме
```bash
mix phx.server
```

### Тестирование
```bash
mix test
```

### Линтинг
```bash
mix format
mix credo
```

### Миграции
```bash
# Создание новой миграции
mix ecto.gen.migration create_table_name

# Запуск миграций
mix ecto.migrate

# Откат миграции
mix ecto.rollback
```

## Конфигурация

### Переменные окружения

| Переменная | Описание | По умолчанию |
|------------|----------|--------------|
| `DB_USERNAME` | Имя пользователя БД | postgres |
| `DB_PASSWORD` | Пароль БД | postgres |
| `DB_HOST` | Хост БД | localhost |
| `DB_NAME` | Имя БД | telegram_admin_api_dev |
| `GUARDIAN_SECRET_KEY` | Секретный ключ для JWT | (генерируется) |
| `POOL_SIZE` | Размер пула соединений | 10 |

### Production настройки

1. Установите секретный ключ:
```bash
export GUARDIAN_SECRET_KEY=$(mix phx.gen.secret)
```

2. Настройте SSL:
```bash
mix phx.gen.cert
```

3. Запустите в production:
```bash
MIX_ENV=prod mix phx.server
```

## Мониторинг

### Health Check
```bash
curl http://localhost:4000/api/v1/health
```

### Логирование
- Структурированные логи в JSON формате
- Уровни: debug, info, warn, error
- Request ID для трассировки

### Telemetry
- Метрики Phoenix
- Метрики базы данных
- VM метрики

## Лучшие практики

### API Design
- RESTful endpoints
- JSON responses
- Proper HTTP status codes
- OpenAPI документация

### Безопасность
- JWT аутентификация
- Rate limiting
- Валидация входных данных
- Хеширование паролей

### Производительность
- Connection pooling
- Индексы в БД
- Кэширование (готово к добавлению)

### Тестирование
- Unit тесты
- Integration тесты
- API тесты

## Структура проекта

```
telegram-admin-api/
├── apps/
│   ├── admin_api/          # REST API
│   ├── core/              # Бизнес-логика
│   ├── shared/            # Общие утилиты
│   └── telegram_api/      # Telegram интеграция
├── config/                # Конфигурация
├── deploy/                # Деплой
└── mix.exs               # Корневой mix файл
```

## Лицензия

MIT License

