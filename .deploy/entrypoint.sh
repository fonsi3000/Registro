#!/bin/sh

echo "📦 Iniciando contenedor de Laravel Octane..."

# ========================================
# 1. Espera adicional para evitar race conditions
# ========================================
echo "🕒 Esperando 10 segundos por inicialización de MySQL..."
sleep 10

# ========================================
# 2. Esperar conexión con la base de datos
# ========================================
MAX_TRIES=60
TRIES=0

echo "⏳ Verificando conexión con la base de datos en $DB_HOST:$DB_PORT..."

until php artisan migrate:status > /dev/null 2>&1; do
  TRIES=$((TRIES + 1))
  if [ "$TRIES" -ge "$MAX_TRIES" ]; then
    echo "❌ No se pudo conectar a la base de datos después de $MAX_TRIES intentos."
    echo "   Verifica credenciales, red y si el contenedor de base de datos está accesible."
    exit 1
  fi
  echo "⏳ Intento $TRIES/$MAX_TRIES... esperando 2 segundos."
  sleep 2
done

echo "✅ Conexión con la base de datos establecida."

# ========================================
# 3. Instalar dependencias si faltan
# ========================================
if [ ! -d vendor ]; then
  echo "🔧 Instalando dependencias con Composer..."
  composer install --no-interaction --prefer-dist --optimize-autoloader
fi

# ========================================
# 4. Limpiar y cachear configuración
# ========================================
echo "⚙️  Generando cachés..."
php artisan config:clear
php artisan route:clear
php artisan view:clear

php artisan config:cache
php artisan route:cache
php artisan view:cache

# ========================================
# 5. Ejecutar migraciones
# ========================================
if [ "$RUN_MIGRATIONS" = "true" ]; then
  echo "🧩 Ejecutando migraciones..."
  php artisan migrate --force || {
    echo "❌ Error durante las migraciones."
    exit 1
  }
fi

# ========================================
# 6. Ejecutar seeders
# ========================================
if [ "$RUN_SEEDERS" = "true" ]; then
  echo "🌱 Ejecutando seeders..."
  php artisan db:seed --force || {
    echo "❌ Error durante los seeders."
    exit 1
  }
fi

# ========================================
# 7. Ajustar permisos
# ========================================
echo "🔐 Ajustando permisos de directorios..."
chmod -R 775 storage bootstrap/cache || true

# ========================================
# 8. Iniciar Supervisor (Octane + Cron)
# ========================================
echo "🚀 Iniciando Supervisor..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
