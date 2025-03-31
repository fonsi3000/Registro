#!/bin/bash

set -e

echo "🚀 Iniciando contenedor de Laravel..."

# Esperar a que la base de datos esté disponible
echo "⌛ Esperando a MySQL en $DB_HOST:$DB_PORT..."
until nc -z "$DB_HOST" "$DB_PORT"; do
  echo "⏳ Esperando a que MySQL esté disponible..."
  sleep 2
done
echo "✅ MySQL está disponible."

# Instalar dependencias de composer si no existen
if [ ! -d "vendor" ]; then
  echo "📦 Instalando dependencias con Composer..."
  composer install --no-interaction --prefer-dist --optimize-autoloader
fi

# Generar APP_KEY si no está definido
if [ -z "$APP_KEY" ]; then
  echo "🔑 Generando APP_KEY..."
  php artisan key:generate
fi

# Ejecutar migraciones si está habilitado en .env
if [ "$RUN_MIGRATIONS" = "true" ]; then
  echo "📂 Ejecutando migraciones..."
  php artisan migrate --force
fi

# Ejecutar seeders si está habilitado en .env
if [ "$RUN_SEEDERS" = "true" ]; then
  echo "🌱 Ejecutando seeders..."
  php artisan db:seed --force
fi

# Configurar permisos
echo "🔒 Configurando permisos..."
chmod -R 775 storage bootstrap/cache

# Iniciar supervisord (cron + octane)
echo "🧠 Iniciando supervisord (cron + Octane)..."
exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisor.conf
