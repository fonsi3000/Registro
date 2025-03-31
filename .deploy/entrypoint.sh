#!/bin/bash
set -e

echo "🚀 Iniciando aplicación Laravel con Octane (Swoole)..."

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
        if ! grep -q "Laravel\\\\Octane\\\\OctaneServiceProvider" config/app.php; then
            sed -i "/App\\\\Providers\\\\RouteServiceProvider::class,/a \        Laravel\\\\Octane\\\\OctaneServiceProvider::class," config/app.php
        fi
        php artisan config:clear
    fi
fi

# Esperar a que la base de datos esté disponible
echo "⏳ Esperando a que la base de datos esté disponible..."
max_retries=30
counter=0
until php -r "try { new PDO('${DB_CONNECTION}:host=${DB_HOST};port=${DB_PORT}', '${DB_USERNAME}', '${DB_PASSWORD}'); echo 'Conexión exitosa\n'; } catch (\Exception \$e) { throw \$e; }" > /dev/null 2>&1
do
    counter=$((counter+1))
    if [ $counter -gt $max_retries ]; then
        echo "⚠️ No se pudo conectar a la base de datos después de $max_retries intentos. Continuando de todos modos..."
        break
    fi
    echo "⏳ Intentando conectar a la base de datos... ($counter/$max_retries)"
    sleep 2
done

# Optimizaciones para producción
if [ "$APP_ENV" = "production" ]; then
    echo "⚡ Optimizando para producción..."
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
fi

# Ejecutar migraciones si está configurado
if [ "${RUN_MIGRATIONS}" = "true" ]; then
    echo "🔄 Ejecutando migraciones..."
    php artisan migrate --force || true
    
    # Ejecutar seeders si está configurado
    if [ "${RUN_SEEDERS}" = "true" ]; then
        echo "🌱 Ejecutando seeders..."
        php artisan db:seed --force || true
    fi
fi

# Crear enlace simbólico para storage si no existe
if [ ! -L "public/storage" ]; then
    echo "🔗 Creando enlace simbólico para storage..."
    php artisan storage:link || true
fi

# Verificar permisos
echo "🔒 Verificando permisos..."
mkdir -p storage/logs bootstrap/cache
touch storage/logs/laravel.log
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache

# Si hay argumentos, ejecutarlos como comando
if [ $# -gt 0 ]; then
    exec "$@"
else
    # Iniciar Octane con Swoole
    echo "🚀 Iniciando Octane con Swoole..."
    exec php artisan octane:start --server=swoole --host=0.0.0.0 --port=8000
fi