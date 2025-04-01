FROM php:8.2-fpm-alpine

# Instala extensiones necesarias del sistema y PHP, incluyendo netcat y la extensión redis
RUN apk add --no-cache \
    bash git unzip libzip-dev libpng-dev libxml2-dev \
    icu-dev oniguruma-dev tzdata curl supervisor shadow nginx openssl \
    netcat-openbsd \
    && docker-php-ext-install pdo pdo_mysql mbstring zip exif pcntl intl \
    && pecl install redis \
    && docker-php-ext-enable redis

# Instala Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Establece el directorio de trabajo
WORKDIR /var/www/html

# Copia el código de la app
COPY . .

# Establece los permisos correctos para Laravel
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Copia archivos de configuración personalizados
COPY .deploy/config/php.ini /usr/local/etc/php/php.ini
COPY .deploy/config/supervisor.conf /etc/supervisord.conf
COPY .deploy/config/crontab /etc/crontabs/root
COPY .deploy/entrypoint.sh /entrypoint.sh

# Da permisos de ejecución al entrypoint
RUN chmod +x /entrypoint.sh

# Expone el puerto por defecto de PHP-FPM
EXPOSE 9000

# Ejecuta el entrypoint al iniciar el contenedor
CMD ["/entrypoint.sh"]
