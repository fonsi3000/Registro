#!/bin/bash
set -e

# Esperar a que la base de datos esté lista
echo "Esperando que la base de datos esté lista..."
sleep 5

cd /var/www/html

# Verificar si existe el archivo .env, si no, copiarlo del ejemplo
if [ ! -f .env ]; then
    echo "Archivo .env no encontrado, creando a partir de .env.example..."
    cp .env.example .env
fi

# Establecer permisos correctos
echo "Configurando permisos..."
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html/storage /var/www/html/bootstrap/cache

# Instalar dependencias si vendor no existe
if [ ! -d vendor ]; then
    echo "Instalando dependencias PHP..."
    composer install --no-interaction --no-dev --optimize-autoloader
fi

# Generar clave si no existe
if ! grep -q "APP_KEY=" .env || grep -q "APP_KEY=base64:" .env; then
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

# Optimizar la aplicación
echo "Optimizando la aplicación..."
php artisan optimize
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Iniciar supervisor para gestionar procesos
echo "Iniciando supervisor..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf