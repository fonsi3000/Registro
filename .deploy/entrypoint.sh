#!/bin/bash
set -e

echo "🚀 Iniciando aplicación Laravel 11 con Octane..."

# Esperar a que la base de datos esté disponible
echo "⏳ Esperando a que la base de datos esté disponible..."
sleep 10

# Optimizaciones para producción
if [ "$APP_ENV" = "production" ]; then
    echo "⚡ Optimizando para producción..."
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
fi

# Ejecutar migraciones si está configurado
if [ "$RUN_MIGRATIONS" = "true" ]; then
    echo "🔄 Ejecutando migraciones..."
    php artisan migrate --force || true
fi

# Crear enlace simbólico para storage si no existe
if [ ! -L "public/storage" ]; then
    echo "🔗 Creando enlace simbólico para storage..."
    php artisan storage:link
fi

# Verificar permisos
echo "🔒 Verificando permisos..."
mkdir -p storage/logs
touch storage/logs/laravel.log
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache

# Iniciar supervisord
echo "🚦 Iniciando servicios con Octane..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf