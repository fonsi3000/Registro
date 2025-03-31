FROM php:8.2-cli

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    build-essential \
    libpng-dev \
    libjpeg-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    curl \
    git \
    supervisor \
    libzip-dev \
    libbrotli-dev \
    vim \
    cron \
    netcat-openbsd \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Instalar Swoole
RUN pecl install swoole && docker-php-ext-enable swoole

# Configuración PHP personalizada (usando ARG solo para build-time)
ARG PHP_MEMORY_LIMIT=256M
ARG PHP_MAX_EXECUTION_TIME=300
ARG PHP_UPLOAD_MAX_FILESIZE=100M
ARG PHP_POST_MAX_SIZE=100M
ARG OPCACHE_MEMORY_CONSUMPTION=128
ARG OPCACHE_VALIDATE_TIMESTAMPS=0

RUN echo "memory_limit=${PHP_MEMORY_LIMIT}" > /usr/local/etc/php/conf.d/limits.ini \
    && echo "max_execution_time=${PHP_MAX_EXECUTION_TIME}" >> /usr/local/etc/php/conf.d/limits.ini \
    && echo "upload_max_filesize=${PHP_UPLOAD_MAX_FILESIZE}" >> /usr/local/etc/php/conf.d/limits.ini \
    && echo "post_max_size=${PHP_POST_MAX_SIZE}" >> /usr/local/etc/php/conf.d/limits.ini

RUN echo "opcache.enable=1" > /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.validate_timestamps=${OPCACHE_VALIDATE_TIMESTAMPS}" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.memory_consumption=${OPCACHE_MEMORY_CONSUMPTION}" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.interned_strings_buffer=16" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.max_accelerated_files=10000" >> /usr/local/etc/php/conf.d/opcache.ini

# Directorio de trabajo
WORKDIR /var/www

# Copiar configuraciones
COPY .deploy/entrypoint.sh /entrypoint.sh
COPY .deploy/config/supervisor.conf /etc/supervisor/conf.d/supervisor.conf
COPY .deploy/config/crontab /etc/cron.d/laravel

RUN chmod +x /entrypoint.sh \
    && chmod 0644 /etc/cron.d/laravel \
    && crontab /etc/cron.d/laravel

ENTRYPOINT ["/entrypoint.sh"]