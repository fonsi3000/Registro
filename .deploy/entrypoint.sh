#!/bin/sh

echo "⏳ Esperando que MySQL esté disponible..."
until nc -z registros_db 3306; do
  echo "MySQL aún no responde, reintentando..."
  sleep 2
done
echo "✅ MySQL disponible"

echo "⏳ Esperando que Redis esté disponible..."
until nc -z registros_redis 6379; do
  echo "Redis aún no responde, reintentando..."
  sleep 2
done
echo "✅ Redis disponible"

# Git safe directory para evitar advertencias
git config --global --add safe.directory /var/www/html

echo "📦 Instalando dependencias con Composer..."
composer install --no-dev --optimize-autoloader || {
  echo "❌ Falló composer install"
  exit 1
}

echo "⚙️ Ejecutando comandos de Laravel..."
php artisan config:cache
php artisan route:cache
php artisan migrate --force

# Ignorar error si el enlace ya existe
php artisan storage:link || true

# Solo genera la key si no existe
if [ ! -f .env ] || ! grep -q '^APP_KEY=base64:' .env; then
  php artisan key:generate
fi

echo "✅ Laravel listo para producción"

# Inicia Supervisor (PHP-FPM + Cron)
exec supervisord -c /etc/supervisord.conf
