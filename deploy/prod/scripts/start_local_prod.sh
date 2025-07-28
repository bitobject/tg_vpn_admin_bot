#!/bin/bash

# Устанавливаем корневую директорию проекта
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." &> /dev/null && pwd )"

# Путь к файлу deploy/prod/dev.env
ENV_FILE="$PROJECT_ROOT/deploy/prod/dev.env"

# Проверяем, существует ли файл deploy/prod/dev.env
if [ ! -f "$ENV_FILE" ]; then
    echo "Ошибка: Файл с переменными окружения не найден по пути $ENV_FILE"
    exit 1
fi

# Экспортируем переменные из файла .env.dev
echo "Загрузка переменных окружения из $ENV_FILE..."
export $(grep -v '^#' "$ENV_FILE" | xargs)

# Переходим в корневую директорию проекта и запускаем сервер
echo "Запуск Phoenix сервера в режиме 'prod'..."
cd "$PROJECT_ROOT" && MIX_ENV=prod iex -S mix phx.server
