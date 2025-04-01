#!/bin/sh
set -e

echo "🎬 entrypoint.sh: [app] [PHP $(php -r 'echo phpversion();')]"

# Esperar a que la base de datos esté lista (opcional)
if [ -n "$DB_HOST" ]; then
    until nc -z -v -w30 $DB_HOST $DB_PORT; do
        echo "🔄 Esperando a que la base de datos ($DB_HOST:$DB_PORT) esté disponible..."
        sleep 2
    done
fi

# Verificar permisos y directorios críticos
for dir in storage/app storage/framework storage/logs bootstrap/cache; do
    if [ ! -d "$LARAVEL_PATH/$dir" ]; then
        mkdir -p "$LARAVEL_PATH/$dir"
        echo "📂 Directorio creado: $dir"
    fi
done

# Finalizar la instalación de Composer
echo "🎮 dump-autoload"
composer dump-autoload --optimize --quiet || true

# Comandos de artisan
echo "🎬 artisan commands"

# Migraciones y caché (solo si DB está configurada)
if [ -n "$DB_CONNECTION" ]; then
    php artisan migrate --force || true
    php artisan config:cache || true
    php artisan route:cache || true
    php artisan view:cache || true
fi

# Iniciar supervisord para gestionar los procesos
echo "🚀 start supervisord"
exec /usr/local/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf