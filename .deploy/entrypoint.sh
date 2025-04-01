#!/bin/sh

echo "Esperando que MySQL esté disponible..."

# Esperar hasta que el puerto 3306 esté disponible en registros_db
until nc -z registros_db 3306; do
  echo "MySQL aún no responde, reintentando..."
  sleep 2
done

echo "MySQL disponible, continuando setup Laravel..."

# Opcional si Git lanza advertencias:
git config --global --add safe.directory /var/www/html

# Instalar dependencias (solo si es necesario en producción)
composer install --no-dev --optimize-autoloader

# Laravel setup
php artisan config:cache
php artisan route:cache
php artisan migrate --force
php artisan storage:link
php artisan key:generate

# Lanzar supervisord (que maneja PHP-FPM y cron)
exec supervisord -c /etc/supervisord.conf
