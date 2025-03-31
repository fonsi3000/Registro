FROM elrincondeisma/php-for-laravel:8.3.7

WORKDIR /var/www/html

# Copiar código de la aplicación
COPY . .

# Instalar dependencias
RUN composer install --optimize-autoloader --no-dev

# Instalar Octane si no está ya instalado
RUN composer require laravel/octane --with-all-dependencies

# Copiar archivo de entorno
COPY .env.production .env

# Crear directorios necesarios
RUN mkdir -p /var/www/html/storage/logs

# Instalar Octane con Swoole
RUN php artisan octane:install --server="swoole"

# Asegurar que el entrypoint sea ejecutable
COPY .deploy/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Configurar permisos
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Exponer el puerto de Octane
EXPOSE 8000

# Usar el script de entrypoint para inicializar correctamente
ENTRYPOINT ["/entrypoint.sh"]

# Este CMD se ejecutará si el entrypoint lo permite
CMD ["php", "artisan", "octane:start", "--server=swoole", "--host=0.0.0.0", "--port=8000"]