#!/bin/sh

# Esperar a que la base de datos esté lista
echo "Esperando a MySQL..."
until nc -z -v -w30 "$DB_HOST" "$DB_PORT"; do
  echo "Esperando a que MySQL ($DB_HOST:$DB_PORT) esté disponible..."
  sleep 5
done

# Instalar dependencias si no existen
if [ ! -d "vendor" ]; then
    echo "Instalando dependencias de Composer..."
    composer install --optimize-autoloader --no-dev
fi

# Generar clave si no está seteada
if [ -z "$APP_KEY" ]; then
    php artisan key:generate
fi

# Migraciones y seeders
if [ "$RUN_MIGRATIONS" = "true" ]; then
    php artisan migrate --force
fi

if [ "$RUN_SEEDERS" = "true" ]; then
    php artisan db:seed --force
fi

# Iniciar servicios
service cron start
supervisord -c /etc/supervisor/conf.d/supervisor.conf &

# Iniciar Octane
php artisan octane:start --server=${OCTANE_SERVER} --host=0.0.0.0 --port=${OCTANE_PORT}