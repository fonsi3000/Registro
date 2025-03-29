#!/bin/bash
set -e

echo "🚀 Iniciando aplicación Laravel 11..."

# Optimizaciones Laravel
echo "⚡ Optimizando para producción..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Esperar a que MySQL esté disponible
echo "⏳ Esperando a que la base de datos esté disponible..."
sleep 10

# Migraciones
echo "🔄 Ejecutando migraciones para crear tablas del sistema..."
php artisan migrate --force || true

# Crear enlace simbólico para storage si no existe
if [ ! -L "public/storage" ]; then
    echo "🔗 Creando enlace simbólico para storage..."
    php artisan storage:link
fi

# Verificar permisos
echo "🔒 Verificando permisos..."
mkdir -p storage/logs
touch storage/logs/laravel.log
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache

# Iniciar supervisord de manera separada
echo "🚦 Iniciando servicios..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf