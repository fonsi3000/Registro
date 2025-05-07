FROM php:8.2-fpm-alpine

# Instala extensiones necesarias del sistema y PHP, incluyendo Redis y Swoole
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
    $PHPIZE_DEPS \
    && printf "\n" | pecl install redis \
    && printf "\n" | pecl install swoole-5.0.3 \
    && docker-php-ext-enable redis swoole \
    && docker-php-ext-install \
    pdo \
    pdo_mysql \
    mbstring \
    zip \
    exif \
    pcntl \
    intl

# Instala Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Establece el directorio de trabajo
WORKDIR /var/www/html

# Copia el código fuente del proyecto
COPY . .

# Asigna permisos adecuados para Laravel
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Copia configuración personalizada
COPY .deploy/config/php.ini /usr/local/etc/php/php.ini
COPY .deploy/config/supervisor.conf /etc/supervisord.conf
COPY .deploy/config/crontab /etc/crontabs/root
COPY .deploy/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expone el puerto de Octane (Swoole)
EXPOSE 9000

# Ejecuta el script de entrada que arranca Laravel y supervisord s
CMD ["/entrypoint.sh"]
