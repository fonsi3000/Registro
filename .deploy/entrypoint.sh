#!/bin/sh

echo "Esperando que MySQL esté disponible..."
# Esperar hasta que el puerto 3306 esté disponible en registros_db
until nc -z registros_db 3306; do
  echo "MySQL aún no responde, reintentando..."
  sleep 2
done
echo "MySQL disponible ✅"

echo "Esperando que Redis esté disponible..."
# Esperar hasta que el puerto 6379 esté disponible en registros_redis
until nc -z registros_redis 6379; do
  echo "Redis aún no responde, reintentando..."
  sleep 2
done
echo "Redis disponible ✅"

# Git safe directory por seguridad en producción
git config --global --add safe.directory /var/www/html

echo "Instalando dependencias con Composer..."
composer install --no-dev --optimize-autoloader || {
  echo "❌ Falló composer install"
  exit 1
}

echo "Ejecutando comandos de Laravel..."
php artisan config:cache
php artisan route:cache
php artisan migrate --force
php artisan storage:link
php artisan key:generate

echo "Setup Laravel completado ✅"

# Lanzar supervisord (que maneja PHP-FPM y cron)
exec supervisord -c /etc/supervisord.conf
