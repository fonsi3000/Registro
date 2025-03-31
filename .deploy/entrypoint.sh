#!/bin/sh

echo "📦 Iniciando contenedor app..."

sleep 5

if [ ! -d vendor ]; then
  echo "🔧 Instalando dependencias..."
  composer install --no-interaction --prefer-dist --optimize-autoloader
fi

php artisan config:cache
php artisan route:cache
php artisan view:cache

if [ "$RUN_MIGRATIONS" = "true" ]; then
  echo "🧩 Ejecutando migraciones..."
  php artisan migrate --force
fi

if [ "$RUN_SEEDERS" = "true" ]; then
  echo "🌱 Ejecutando seeders..."
  php artisan db:seed --force
fi

echo "🚀 Iniciando Supervisor..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
