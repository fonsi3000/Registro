FROM php:8.2-fpm

# Argumentos de construcción definidos en el docker-compose.yml
ARG PHP_MEMORY_LIMIT
ARG PHP_MAX_EXECUTION_TIME
ARG PHP_UPLOAD_MAX_FILESIZE
ARG PHP_POST_MAX_SIZE
ARG OPCACHE_VALIDATE_TIMESTAMPS
ARG OPCACHE_MEMORY_CONSUMPTION

# Instalar dependencias
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libzip-dev \
    libicu-dev \
    cron \
    supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Instalar extensiones PHP
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip intl opcache

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
RUN pecl install redis && docker-php-ext-enable redis

# Instalar Swoole para Octane
RUN pecl install swoole
RUN docker-php-ext-enable swoole

# Obtener Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configuración de PHP personalizada si existe
COPY .deploy/php.ini /usr/local/etc/php/conf.d/custom.ini

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

ENTRYPOINT ["/entrypoint.sh"]