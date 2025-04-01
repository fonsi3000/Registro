FROM php:8.2-fpm-alpine

# Instala herramientas del sistema, PHP y dependencias para compilar Redis
RUN apk add --no-cache \
    bash git unzip libzip-dev libpng-dev libxml2-dev \
    icu-dev oniguruma-dev tzdata curl supervisor shadow nginx openssl \
    netcat-openbsd \
    autoconf g++ make \
    && docker-php-ext-install pdo pdo_mysql mbstring zip exif pcntl intl \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del autoconf g++ make

# Instala Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Establece el directorio de trabajo
WORKDIR /var/www/html

# Copia el código de la app
COPY . .

# Permisos
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Copia configuración
COPY .deploy/config/php.ini /usr/local/etc/php/php.ini
COPY .deploy/config/supervisor.conf /etc/supervisord.conf
COPY .deploy/config/crontab /etc/crontabs/root
COPY .deploy/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 9000

CMD ["/entrypoint.sh"]
