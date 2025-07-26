#!/bin/sh
# entrypoint.sh

# Exit immediately if a command exits with a non-zero status.
set -e

# Запускаем миграции
echo "Running database migrations..."
/app/bin/migrate

# Затем запускаем основной сервер
echo "Starting server..."
exec /app/bin/server
