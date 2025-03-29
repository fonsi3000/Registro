#!/bin/bash
set -e

echo "🚀 Iniciando aplicación Laravel 11..."

# Verificar y generar APP_KEY si es necesario
if [ -z "$APP_KEY" ] || [ "$APP_KEY" = "base64:TuClaveGeneradaConPhpArtisanKeyGenerate" ]; then
    echo "🔑 Generando clave de aplicación..."
    php artisan key:generate --force
fi

# Verificar entorno y optimizar según corresponda
if [ "$APP_ENV" = "production" ]; then
    echo "⚡ Optimizando para producción..."
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
fi

# Ejecutar migraciones (crucial para crear la tabla cache)
echo "🔄 Ejecutando migraciones para crear tablas del sistema..."
php artisan migrate --force
php artisan cache:table
php artisan migrate --force

# Crear enlace simbólico para storage
if [ ! -L "public/storage" ]; then
    echo "🔗 Creando enlace simbólico para storage..."
    php artisan storage:link
fi

# Asegurar permisos correctos antes de iniciar servicios
echo "🔒 Verificando permisos..."
mkdir -p /var/www/html/storage/logs
touch /var/www/html/storage/logs/laravel.log
touch /var/www/html/storage/logs/php-fpm.log
find /var/www/html/storage -type d -exec chmod 775 {} \;
find /var/www/html/storage -type f -exec chmod 664 {} \;
chmod -R 775 /var/www/html/bootstrap/cache
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Iniciar servicios con supervisor
echo "🚦 Iniciando servicios..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf