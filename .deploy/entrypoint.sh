#!/bin/sh

# Instalar dependencias si no están
composer install --no-dev --optimize-autoloader

# Cache Laravel
php artisan config:cache
php artisan route:cache

# Migraciones
php artisan migrate --force

# Permisos
chown -R www-data:www-data /var/www/html

# Lanzar supervisord (php-fpm y cron)
exec supervisord -c /etc/supervisord.conf
