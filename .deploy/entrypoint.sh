#!/bin/sh

echo "🎬 entrypoint.sh: [$(whoami)] [PHP $(php -r 'echo phpversion();')]"

# Composer autoload
composer dump-autoload --no-interaction --no-dev --optimize || true

echo "🎬 artisan commands"

# Enlace de storage
php artisan storage:link || true

# Ajuste de permisos por si falló en Dockerfile
chmod -R ug+rwX storage bootstrap/cache || true

echo "🚀 start supervisord"
exec supervisord -c /etc/supervisor/conf.d/supervisord.conf
