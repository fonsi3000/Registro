#!/bin/sh
set -e

# Script de entrada para el contenedor de la aplicación Laravel

# Comprobamos entorno
if [ "$APP_ENV" = "local" ] || [ "$APP_ENV" = "development" ]; then
    echo "🧪 Entorno de desarrollo detectado"
    
    # Generamos key si no existe
    if [ -z "$APP_KEY" ] || [ "$APP_KEY" = "base64:SomeRandomString" ]; then
        echo "🔑 Generando clave de aplicación..."
        php artisan key:generate --force
    fi
    
    # En desarrollo, ejecutamos Vite en modo desarrollo
    if [ -f "vite.config.js" ]; then
        echo "🔥 Iniciando compilación de assets en modo desarrollo..."
        npm run dev &
    fi
else
    # En producción, optimizamos y compilamos assets
    echo "🚀 Entorno de producción detectado"
    
    # Optimizaciones de Laravel para producción
    echo "⚡ Optimizando para producción..."
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
    
    # Compilar assets para producción
    if [ -f "vite.config.js" ]; then
        echo "📦 Compilando assets para producción..."
        
        # Verificamos si node_modules existe y está completo
        if [ ! -d "node_modules/.bin" ]; then
            echo "📦 Instalando dependencias de Node.js..."
            npm ci || npm install
        fi
        
        # Compilación de assets con múltiples intentos y manejo de errores
        echo "🔨 Compilando assets con Vite..."
        
        # Intento 1: npm run build (método estándar)
        npm run build || {
            echo "⚠️ npm run build falló, intentando con método alternativo..."
            
            # Intento 2: npx vite build
            npx vite build || {
                echo "⚠️ npx vite build falló, intentando con acceso directo al binario..."
                
                # Intento 3: usar directamente el binario de vite
                node_modules/.bin/vite build || {
                    echo "⚠️ Todos los métodos de compilación fallaron."
                    echo "🔍 Verificando entorno:"
                    echo "- Node: $(node -v)"
                    echo "- NPM: $(npm -v)"
                    echo "- Vite instalado: $(ls -la node_modules/vite 2>/dev/null || echo 'No')"
                    
                    # Intento 4: instalación fresca de vite
                    echo "🔄 Intentando instalar Vite específicamente..."
                    npm install --save-dev vite@4.4.9
                    npx vite build || {
                        echo "❌ No se pudo compilar los assets. La aplicación funcionará sin assets compilados."
                    }
                }
            }
        }
    fi
fi

# Ejecutamos migraciones si se nos indica
if [ "$RUN_MIGRATIONS" = "true" ]; then
    echo "🔄 Ejecutando migraciones..."
    php artisan migrate --force
fi

# Creamos enlace simbólico para storage si no existe
if [ ! -L "public/storage" ]; then
    echo "🔗 Creando enlace simbólico para storage..."
    php artisan storage:link
fi

# Establecemos los permisos correctos
echo "🔒 Estableciendo permisos..."
find /var/www/html/storage -type d -exec chmod 775 {} \;
find /var/www/html/storage -type f -exec chmod 664 {} \;
chmod -R 775 /var/www/html/bootstrap/cache
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Iniciamos supervisor (que gestiona PHP-FPM, Caddy y colas)
echo "🚦 Iniciando servicios..."
exec /usr/local/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf