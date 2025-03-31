#!/bin/sh

echo "📦 Iniciando contenedor de Laravel Octane..."

# ========================================
# 1. Esperar conexión con la base de datos
# ========================================
MAX_TRIES=30
TRIES=0

echo "⏳ Verificando conexión con la base de datos en $DB_HOST:$DB_PORT..."

until php artisan migrate:status > /dev/null 2>&1; do
  TRIES=$((TRIES + 1))
  if [ "$TRIES" -ge "$MAX_TRIES" ]; then
    echo "❌ No se pudo conectar a la base de datos después de $MAX_TRIES intentos."
    echo "   Verifica que el contenedor de MySQL esté levantado y accesible desde la app."
    exit 1
  fi
  echo "⏳ Intento $TRIES/$MAX_TRIES... esperando 2 segundos."
  sleep 2
done

echo "✅ Base de datos disponible."

# ========================================
# 2. Instalar dependencias si faltan
# ========================================
if [ ! -d vendor ]; then
  echo "🔧 Instalando dependencias con Composer..."
  composer install --no-interaction --prefer-dist --optimize-autoloader
fi

# ========================================
# 3. Cache de Laravel
# ========================================
echo "⚙️  Limpiando y generando caché de Laravel..."
php artisan config:clear
php artisan route:clear
php artisan view:clear

php artisan config:cache
php artisan route:cache
php artisan view:cache

# ========================================
# 4. Ejecutar migraciones
# ========================================
if [ "$RUN_MIGRATIONS" = "true" ]; then
  echo "🧩 Ejecutando migraciones..."
  php artisan migrate --force || {
    echo "❌ Error al ejecutar migraciones. Revisa tus archivos de migración o conexión de base de datos."
    exit 1
  }
fi

# ========================================
# 5. Ejecutar seeders
# ========================================
if [ "$RUN_SEEDERS" = "true" ]; then
  echo "🌱 Ejecutando seeders..."
  php artisan db:seed --force || {
    echo "❌ Error al ejecutar seeders."
    exit 1
  }
fi

# ========================================
# 6. Permisos
# ========================================
echo "🔐 Verificando permisos de storage y cache..."
chmod -R 775 storage bootstrap/cache || true

# ========================================
# 7. Iniciar Supervisor (Octane + Cron)
# ========================================
echo "🚀 Iniciando Supervisor con Octane y Cron..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
