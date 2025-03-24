#!/bin/bash

echo "🎬 entrypoint.sh: [$(whoami)] [PHP $(php -r 'echo phpversion();')]"

# Cambiar al directorio de la aplicación
cd $LARAVEL_PATH

# Optimizar autoloader
composer dump-autoload --no-interaction --no-dev --optimize

echo "🎬 artisan commands"

# Limpiar y regenerar caché
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan cache:clear

# Regenerar caché optimizada para producción
php artisan config:cache
php artisan route:cache

# Asegurarse de que los directorios de almacenamiento tengan permisos adecuados
chmod -R 775 $LARAVEL_PATH/storage $LARAVEL_PATH/bootstrap/cache
chown -R www-data:www-data $LARAVEL_PATH/storage $LARAVEL_PATH/bootstrap/cache

# Asegurarse de que PHP-FPM está configurado correctamente
service php8.2-fpm start

# Comentados pero disponibles para activar según sea necesario
# php artisan migrate --no-interaction --force
# php artisan db:seed --no-interaction --force

echo "🎬 start supervisord"

# Iniciar todos los servicios con supervisord
exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf