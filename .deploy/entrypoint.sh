#!/bin/sh

echo "🎬 entrypoint.sh: [$(whoami)] [PHP $(php -r 'echo phpversion();')]"

# ========================================
# 1. Instalar dependencias si no existen
# ========================================
if [ ! -d vendor ]; then
  echo "📦 Instalando dependencias..."
  composer install --no-interaction --prefer-dist --optimize-autoloader
fi

# ========================================
# 2. Dump autoload
# ========================================
composer dump-autoload --no-interaction --no-dev --optimize

# ========================================
# 3. Ejecutar comandos de Artisan
# ========================================
echo "🎬 artisan commands"

# ⚠️ Crea enlace simbólico al directorio de storage
php artisan storage:link

# ⚠️ Ejecutar migraciones si se desea
if [ "$RUN_MIGRATIONS" = "true" ]; then
  echo "🧩 Ejecutando migraciones..."
  php artisan migrate --force
fi

# ⚠️ Ejecutar seeders si se desea
if [ "$RUN_SEEDERS" = "true" ]; then
  echo "🌱 Ejecutando seeders..."
  php artisan db:seed --force
fi

# ========================================
# 4. Compilar assets si no existen
# ========================================
if [ ! -f public/build/manifest.json ]; then
  echo "🎨 Compilando assets con Vite (modo producción)..."
  if command -v npm >/dev/null 2>&1; then
    npm ci
    npm run build
  else
    echo "⚠️ npm no está disponible, no se compilaron assets."
  fi
fi

# ========================================
# 5. Ajustar permisos
# ========================================
echo "🔐 Ajustando permisos..."
chmod -R 775 storage bootstrap/cache || true

# ========================================
# 6. Iniciar supervisord
# ========================================
echo "🚀 start supervisord"
exec supervisord -c $LARAVEL_PATH/.deploy/config/supervisor.conf
