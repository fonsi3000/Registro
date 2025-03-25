#!/bin/bash

cd /var/www/html

# Instalar dependencias si es necesario
if [ "$APP_ENV" != "local" ]; then
    composer install --optimize-autoloader --no-dev
fi

# Generar clave y optimizar
php artisan key:generate --force
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Otorgar permisos
chown -R www:www /var/www/html
chmod -R 775 storage bootstrap/cache

# Iniciar supervisor (que maneja Nginx y Octane)
exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf