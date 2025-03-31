#!/bin/bash
set -e

cd $LARAVEL_PATH

# Esperar a que la base de datos esté lista
echo "Esperando a que la base de datos esté lista..."
sleep 5

# Verificar si existe el archivo .env
if [ ! -f .env ]; then
    echo "Archivo .env no encontrado, creando desde variables de entorno..."
    touch .env
fi

# Establecer permisos
echo "Configurando permisos..."
chown -R www-data:www-data $LARAVEL_PATH
chmod -R 755 $LARAVEL_PATH/storage $LARAVEL_PATH/bootstrap/cache

# Instalar dependencias si no existen
if [ ! -d vendor ] || [ ! -f vendor/autoload.php ]; then
    echo "Instalando dependencias PHP..."
    composer install --no-interaction --no-dev --optimize-autoloader
else
    echo "Las dependencias ya están instaladas."
fi

# Generar autoloader optimizado
composer dump-autoload --optimize

# Generar clave si no existe
if [ -z "$APP_KEY" ] || [ "$APP_KEY" = "base64:TuClaveGeneradaConPhpArtisanKeyGenerate" ]; then
    echo "Generando clave de la aplicación..."
    php artisan key:generate --force
fi

# Ejecutar migraciones si RUN_MIGRATIONS=true
if [ "${RUN_MIGRATIONS}" = "true" ]; then
    echo "Ejecutando migraciones..."
    php artisan migrate --force
fi

# Ejecutar seeders si RUN_SEEDERS=true
if [ "${RUN_SEEDERS}" = "true" ]; then
    echo "Ejecutando seeders..."
    php artisan db:seed --force
fi

# Borrar caché y regenerarla
php artisan optimize:clear
php artisan route:cache
php artisan config:cache
php artisan view:cache

# Instalar Octane si es necesario
php artisan octane:install --server=$OCTANE_SERVER --no-interaction

# Iniciar Supervisord
echo "Iniciando supervisord..."
exec /usr/local/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf