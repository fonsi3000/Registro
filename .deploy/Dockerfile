FROM php:8.2-fpm-alpine

# Instala dependencias necesarias
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
    openssl \
    netcat-openbsd \
    autoconf \
    g++ \
    make \
    linux-headers \
    $PHPIZE_DEPS

# Instala extensiones PECL sin interacción
RUN printf "\n" | pecl install redis \
    && docker-php-ext-enable redis

RUN printf "\n" | pecl install swoole-5.1.0 \
    && docker-php-ext-enable swoole

# Instala extensiones PHP nativas
RUN docker-php-ext-install \
    pdo \
    pdo_mysql \
    mbstring \
    zip \
    exif \
    pcntl \
    intl

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Código y configuración
WORKDIR /var/www/html
COPY . .

RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

COPY .deploy/config/php.ini /usr/local/etc/php/php.ini
COPY .deploy/config/supervisor.conf /etc/supervisord.conf
COPY .deploy/config/crontab /etc/crontabs/root
COPY .deploy/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 9000
CMD ["/entrypoint.sh"]
