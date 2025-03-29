#!/bin/bash
set -e

echo "🚀 Iniciando aplicación Laravel 11..."

# Verificar entorno y optimizar según corresponda
if [ "$APP_ENV" = "production" ]; then
    echo "⚡ Optimizando para producción..."
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
fi

# Ejecutar migraciones si está configurado
if [ "$RUN_MIGRATIONS" = "true" ]; then
    echo "🔄 Ejecutando migraciones..."
    php artisan migrate --force
fi

# Ejecutar seeders si está configurado
if [ "$RUN_SEEDERS" = "true" ]; then
    echo "🌱 Ejecutando seeders..."
    php artisan db:seed --force
fi

# Crear enlace simbólico para storage
if [ ! -L "public/storage" ]; then
    echo "🔗 Creando enlace simbólico para storage..."
    php artisan storage:link
fi

# Iniciar servicios con supervisor
echo "🚦 Iniciando servicios..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf