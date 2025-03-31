ARG PHP_VERSION=8.2
FROM php:${PHP_VERSION}-fpm-alpine AS base

# Instala dependencias del sistema necesarias
RUN apk add --no-cache \
    bash \
    curl \
    git \
    unzip \
    tzdata \
    libzip-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    libxml2-dev \
    oniguruma-dev \
    icu-dev \
    zlib-dev \
    supervisor \
    vim \
    shadow \
    autoconf \
    g++ \
    make \
    pcre-dev \
    brotli-dev \
    libstdc++ \
    pkgconfig \
    linux-headers \
    re2c \
    file \
    dpkg \
    dpkg-dev

# Instala extensiones PHP
RUN docker-php-ext-install \
    pdo_mysql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    intl \
    zip \
    tokenizer \
    xml \
    opcache \
    && pecl install swoole \
    && docker-php-ext-enable swoole

# Copia composer desde su contenedor oficial
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configuración PHP personalizada
ARG PHP_MEMORY_LIMIT=512M
ARG PHP_MAX_EXECUTION_TIME=300
ARG PHP_UPLOAD_MAX_FILESIZE=100M
ARG PHP_POST_MAX_SIZE=100M
RUN echo "memory_limit=${PHP_MEMORY_LIMIT}" > /usr/local/etc/php/conf.d/limits.ini \
    && echo "max_execution_time=${PHP_MAX_EXECUTION_TIME}" >> /usr/local/etc/php/conf.d/limits.ini \
    && echo "upload_max_filesize=${PHP_UPLOAD_MAX_FILESIZE}" >> /usr/local/etc/php/conf.d/limits.ini \
    && echo "post_max_size=${PHP_POST_MAX_SIZE}" >> /usr/local/etc/php/conf.d/limits.ini

# Configuración OPcache
ARG OPCACHE_VALIDATE_TIMESTAMPS=0
ARG OPCACHE_MEMORY_CONSUMPTION=128
RUN echo "opcache.enable=1" > /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.validate_timestamps=${OPCACHE_VALIDATE_TIMESTAMPS}" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.revalidate_freq=0" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.memory_consumption=${OPCACHE_MEMORY_CONSUMPTION}" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.max_accelerated_files=10000" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.max_wasted_percentage=10" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.interned_strings_buffer=16" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.fast_shutdown=1" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.enable_cli=1" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.jit_buffer_size=100M" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.jit=1235" >> /usr/local/etc/php/conf.d/opcache.ini

# Usuario no root para correr la app
ARG NON_ROOT_USER=www-data
ARG NON_ROOT_GROUP=www-data
RUN addgroup -S $NON_ROOT_GROUP && adduser -S $NON_ROOT_USER -G $NON_ROOT_GROUP

# Directorio de la aplicación
WORKDIR /var/www/html

# Copia archivos del proyecto
COPY --chown=$NON_ROOT_USER:$NON_ROOT_GROUP . /var/www/html

# Permisos de almacenamiento y logs
RUN mkdir -p storage/logs \
    && chown -R $NON_ROOT_USER:$NON_ROOT_GROUP storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Copia configuración de supervisor y cron
COPY .deploy/config/crontab /etc/crontabs/www-data
COPY .deploy/config/supervisor.conf /etc/supervisor/conf.d/supervisord.conf
RUN chmod 0644 /etc/crontabs/$NON_ROOT_USER && chmod +x /usr/sbin/crond

# Entrypoint
COPY .deploy/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8000

ENTRYPOINT ["/entrypoint.sh"]