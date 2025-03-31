#!/bin/bash

echo "🚀 Iniciando contenedor de Laravel..."

# Esperar a MySQL
echo "⌛ Esperando a MySQL en $DB_HOST:$DB_PORT..."
until nc -z "$DB_HOST" "$DB_PORT"; do
  sleep 1
  echo "⏳ Esperando a que MySQL esté disponible..."
done
echo "✅ MySQL está disponible."

# Migraciones
if [ "$RUN_MIGRATIONS" = "true" ]; then
    echo "📂 Ejecutando migraciones..."
    php artisan migrate --force
fi

# Seeders
if [ "$RUN_SEEDERS" = "true" ]; then
    echo "🌱 Ejecutando seeders..."
    php artisan db:seed --force
fi

# Optimización
echo "⚙️ Optimizando aplicación..."
php artisan optimize
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache

# Permisos
echo "🔒 Configurando permisos..."
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Iniciar supervisord
echo "🧠 Iniciando supervisord (cron + Octane)..."
exec supervisord -c /etc/supervisor/conf.d/supervisor.conf
