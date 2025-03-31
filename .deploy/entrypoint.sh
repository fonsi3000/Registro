#!/bin/sh

echo "📦 Iniciando contenedor app..."

# Espera a que la base de datos esté lista
echo "⏳ Esperando a que la base de datos esté lista..."
until php artisan migrate:status > /dev/null 2>&1
do
  echo "⏳ Esperando conexión con la base de datos..."
  sleep 2
done

# Instala dependencias si no están
if [ ! -d vendor ]; then
  echo "🔧 Instalando dependencias..."
  composer install --no-interaction --prefer-dist --optimize-autoloader
fi

# Limpia y cachea configuración
echo "⚙️  Cacheando configuración, rutas y vistas..."
php artisan config:clear
php artisan route:clear
php artisan view:clear

php artisan config:cache
php artisan route:cache
php artisan view:cache

# Migraciones automáticas
if [ "$RUN_MIGRATIONS" = "true" ]; then
  echo "🧩 Ejecutando migraciones..."
  php artisan migrate --force
fi

# Seeders automáticos
if [ "$RUN_SEEDERS" = "true" ]; then
  echo "🌱 Ejecutando seeders..."
  php artisan db:seed --force
fi

# Permisos por si se sobrescriben con el volumen
echo "🔐 Ajustando permisos..."
chmod -R 775 storage bootstrap/cache || true

# Inicia Supervisor (Octane + cron)
echo "🚀 Iniciando Supervisor..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
