#!/bin/bash
set -e

echo "Esperando conexión a la base de datos..."
while ! nc -z db 3306; do
  sleep 1
done

echo "Generando clave de aplicación..."
php artisan key:generate --force

echo "Ejecutando migraciones..."
php artisan migrate --force

echo "Optimizando Laravel..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

echo "Iniciando servidor Octane..."
php artisan octane:start --server=swoole --host=0.0.0.0 --port=9090 --workers=4 --task-workers=2 --max-requests=1000