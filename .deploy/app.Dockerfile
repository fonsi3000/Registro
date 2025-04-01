FROM php:8.2-fpm-alpine

# Instala extensiones necesarias
RUN apk add --no-cache \
    bash \
    git \
    unzip \
    libzip-dev \
    libpng-dev \
    libxml2-dev \
    icu-dev \
    oniguruma-dev \
    tzdata \
    curl \
    supervisor \
    shadow \
    nginx \
    openssl

RUN docker-php-ext-install pdo pdo_mysql mbstring zip exif pcntl intl

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
COPY .deploy/config/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 9000

CMD ["/entrypoint.sh"]
