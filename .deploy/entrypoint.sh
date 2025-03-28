#!/bin/sh
set -e

# Script de entrada para el contenedor de la aplicación Laravel 11

# Comprobamos entorno
if [ "$APP_ENV" = "local" ] || [ "$APP_ENV" = "development" ]; then
    echo "🧪 Entorno de desarrollo detectado"
    # En desarrollo, instalamos dependencias si es necesario
    if [ ! -d "vendor" ] || [ ! -f "vendor/autoload.php" ]; then
        echo "📦 Instalando dependencias de Composer..."
        composer install --no-interaction
    fi
    
    # Generamos key si no existe
    if [ -z "$APP_KEY" ] || [ "$APP_KEY" = "base64:SomeRandomString" ]; then
        echo "🔑 Generando clave de aplicación..."
        php artisan key:generate --force
    fi
    
    # Ejecutamos npm si es necesario
    if [ -f "package.json" ] && [ ! -d "node_modules" ]; then
        echo "📦 Instalando dependencias de Node.js..."
        npm install
        npm run dev
    fi
else
    # En producción, optimizamos
    echo "🚀 Entorno de producción detectado"
    
    if [ ! -d "vendor" ] || [ ! -f "vendor/autoload.php" ]; then
        echo "📦 Instalando dependencias de producción..."
        composer install --no-dev --no-interaction --optimize-autoloader
    fi
    
    # Optimizaciones de Laravel para producción
    echo "⚡ Optimizando para producción..."
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
    
    # Compilar assets si es necesario y npm está disponible
    if [ -f "package.json" ]; then
        echo "📦 Compilando assets para producción..."
        if [ ! -d "node_modules" ]; then
            npm ci --only=production || npm install --only=production
        fi
        npm run build
    fi
fi

# Ejecutamos migraciones si se nos indica
if [ "$RUN_MIGRATIONS" = "true" ]; then
    echo "🔄 Ejecutando migraciones..."
    php artisan migrate --force
fi

# Ejecutamos seeders si se nos indica
if [ "$RUN_SEEDERS" = "true" ]; then
    echo "🌱 Ejecutando seeders..."
    php artisan db:seed --force
fi

# Creamos enlace simbólico para storage si no existe
if [ ! -L "public/storage" ]; then
    echo "🔗 Creando enlace simbólico para storage..."
    php artisan storage:link
fi

# Establecemos los permisos correctos para Laravel 11
echo "🔒 Estableciendo permisos..."
find /var/www/html/storage -type d -exec chmod 775 {} \;
find /var/www/html/storage -type f -exec chmod 664 {} \;
chmod -R 775 /var/www/html/bootstrap/cache
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Iniciamos supervisor (que gestiona PHP-FPM, Caddy y colas)
echo "🚦 Iniciando servicios..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf