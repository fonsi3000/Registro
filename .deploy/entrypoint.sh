#!/bin/sh

echo "🚀 Iniciando contenedor de Laravel..."

# Esperar a que MySQL esté disponible
echo "⌛ Esperando a MySQL en $DB_HOST:$DB_PORT..."
until nc -z -v -w30 $DB_HOST $DB_PORT
do
  echo "⏳ Esperando a que MySQL esté disponible..."
  sleep 5
done
echo "✅ MySQL está disponible."

# Ejecutar migraciones si está habilitado
if [ "$RUN_MIGRATIONS" = "true" ]; then
  echo "📂 Ejecutando migraciones..."
  php artisan migrate --force
fi

# Ejecutar seeders si está habilitado
if [ "$RUN_SEEDERS" = "true" ]; then
  echo "🌱 Ejecutando seeders..."
  php artisan db:seed --force
fi

# Asignar permisos
echo "🔒 Configurando permisos..."
chmod -R ug+rwx storage bootstrap/cache

# Optimización de Laravel
echo "⚡ Optimizando Laravel..."
php artisan optimize

# Iniciar supervisord
echo "🧠 Iniciando supervisord (cron + Octane)..."
exec supervisord -n -c /etc/supervisor/conf.d/supervisor.conf
