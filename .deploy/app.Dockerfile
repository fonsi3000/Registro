FROM php:8.2-fpm-alpine

# Argumentos de construcción definidos en el docker-compose.yml
ARG PHP_MEMORY_LIMIT
ARG PHP_MAX_EXECUTION_TIME
ARG PHP_UPLOAD_MAX_FILESIZE
ARG PHP_POST_MAX_SIZE
ARG OPCACHE_VALIDATE_TIMESTAMPS
ARG OPCACHE_MEMORY_CONSUMPTION

# Instalar dependencias
RUN apk add --no-cache \
    git \
    curl \
    libpng-dev \
    libzip-dev \
    zip \
    unzip \
    icu-dev \
    oniguruma-dev \
    libxml2-dev \
    supervisor \
    dcron \
    bash

# Instalar extensiones PHP
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip intl opcache xml

# Configuración de OPcache para producción
RUN { \
    echo "opcache.enable=1"; \
    echo "opcache.validate_timestamps=${OPCACHE_VALIDATE_TIMESTAMPS}"; \
    echo "opcache.revalidate_freq=0"; \
    echo "opcache.memory_consumption=${OPCACHE_MEMORY_CONSUMPTION}"; \
    echo "opcache.max_accelerated_files=10000"; \
    echo "opcache.max_wasted_percentage=10"; \
    echo "opcache.interned_strings_buffer=16"; \
    echo "opcache.fast_shutdown=1"; \
    } > /usr/local/etc/php/conf.d/opcache.ini

# Configuración de límites PHP
RUN { \
    echo "memory_limit=${PHP_MEMORY_LIMIT}"; \
    echo "max_execution_time=${PHP_MAX_EXECUTION_TIME}"; \
    echo "upload_max_filesize=${PHP_UPLOAD_MAX_FILESIZE}"; \
    echo "post_max_size=${PHP_POST_MAX_SIZE}"; \
    } > /usr/local/etc/php/conf.d/limits.ini

# Instalar Redis
RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del .build-deps

# Instalar Swoole para Octane
RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
    && pecl install swoole \
    && docker-php-ext-enable swoole \
    && apk del .build-deps

# Obtener Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Crear directorios necesarios
RUN mkdir -p /etc/supervisor/conf.d /var/log/supervisor /etc/cron.d

# Configuración de PHP personalizada
COPY .deploy/php.ini /usr/local/etc/php/conf.d/php.ini

# Configuración de Supervisor
COPY .deploy/supervisor.conf /etc/supervisor/conf.d/supervisord.conf

# Crontab configuration
COPY .deploy/crontab /etc/cron.d/laravel-cron
RUN chmod 0644 /etc/cron.d/laravel-cron && crontab /etc/cron.d/laravel-cron

# Entrypoint script
COPY .deploy/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Configurar directorio de trabajo
WORKDIR /var/www/html

# Asegurar que el usuario www-data existe
RUN adduser -u 82 -D -S -G www-data www-data

ENTRYPOINT ["/entrypoint.sh"]