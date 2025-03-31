#!/bin/sh

echo "🚀 Iniciando contenedor de Laravel..."

# Esperar a MySQL si es necesario
if [ -n "$DB_HOST" ]; then
  echo "⌛ Esperando a MySQL en $DB_HOST..."
  while ! nc -z $DB_HOST 3306; do
    sleep 1
    echo "⏳ Esperando a que MySQL esté disponible..."
  done
fi

# Ejecutar migraciones y seeders si está habilitado
if [ "$RUN_MIGRATIONS" = "true" ]; then
  echo "📂 Ejecutando migraciones..."
  php artisan migrate --force
fi

if [ "$RUN_SEEDERS" = "true" ]; then
  echo "🌱 Ejecutando seeders..."
  php artisan db:seed --force
fi

# Cache de Laravel para producción
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache

echo "🔒 Configurando permisos..."
chown -R www-data:www-data storage bootstrap/cache

echo "🧠 Iniciando supervisord (cron + Octane)..."
/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
