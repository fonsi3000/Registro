#!/bin/bash
set -e

echo "🚀 Iniciando aplicación Laravel 11 con Octane..."

# Verificar si Octane está instalado correctamente
if ! composer show | grep -q laravel/octane; then
    echo "📦 Laravel Octane no está instalado, instalando ahora..."
    composer require laravel/octane --with-all-dependencies
fi

# Verificar si el comando octane está disponible
if ! php artisan list | grep -q octane; then
    echo "📦 Comando Octane no disponible, instalando y configurando..."
    php artisan octane:install --server=swoole --force
    
    # Verificar si se ha instalado correctamente
    if ! php artisan list | grep -q octane; then
        echo "🔧 Registrando proveedor de servicios de Octane manualmente..."
        # Verificar si ya existe el proveedor en config/app.php
        if ! grep -q "Laravel\\\\Octane\\\\OctaneServiceProvider" config/app.php; then
            sed -i "/App\\\\Providers\\\\RouteServiceProvider::class,/a \        Laravel\\\\Octane\\\\OctaneServiceProvider::class," config/app.php
        fi
        
        # Limpiar caché después de modificar configuración
        php artisan config:clear
    fi
fi

# Esperar a que la base de datos esté disponible
echo "⏳ Esperando a que la base de datos esté disponible..."
sleep 10

# Optimizaciones para producción
if [ "$APP_ENV" = "production" ]; then
    echo "⚡ Optimizando para producción..."
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
fi

# Ejecutar migraciones si está configurado
if [ "$RUN_MIGRATIONS" = "true" ]; then
    echo "🔄 Ejecutando migraciones..."
    php artisan migrate --force || true
fi

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

# Iniciar supervisord
echo "🚦 Iniciando servicios con Octane..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf