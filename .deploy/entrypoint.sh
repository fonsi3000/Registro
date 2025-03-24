#!/bin/sh

echo "🎬 entrypoint.sh: [$(whoami)] [PHP $(php -r 'echo phpversion();')]"

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
chmod -R 775 /srv/app/storage /srv/app/bootstrap/cache

# Comentados pero disponibles para activar según sea necesario
# php artisan migrate --no-interaction --force
# php artisan db:seed --no-interaction --force

echo "🎬 start supervisord"

# Iniciar todos los servicios con supervisord
supervisord -c /etc/supervisor/conf.d/supervisord.conf