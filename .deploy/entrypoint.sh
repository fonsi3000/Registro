#!/bin/bash

echo "🎬 entrypoint.sh: [$(whoami)] [PHP $(php -r 'echo phpversion();')]"

cd /var/www/html

# Instalar dependencias
composer install --no-interaction --optimize-autoloader --no-dev
composer require laravel/octane --no-interaction

# Generar key y optimizar
php artisan key:generate --force
php artisan config:cache
php artisan route:cache

# Compilar assets frontend
npm install
npm run build
rm -rf node_modules

# Establecer permisos
chown -R www-data:www-data /var/www/html
chmod -R 775 storage bootstrap/cache

# Iniciar servicios con Supervisor
exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf