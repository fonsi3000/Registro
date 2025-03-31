# Etapa 1: Imagen base de PHP con Alpine
FROM php:8.2-cli-alpine

# Variables de entorno para PHP (puedes sobrescribir con ARG si prefieres)
ENV PHP_MEMORY_LIMIT=256M \
    PHP_MAX_EXECUTION_TIME=300 \
    PHP_UPLOAD_MAX_FILESIZE=100M \
    PHP_POST_MAX_SIZE=100M \
    OPCACHE_MEMORY_CONSUMPTION=128 \
    OPCACHE_VALIDATE_TIMESTAMPS=0

# Instalar dependencias del sistema y extensiones de PHP necesarias para Laravel
RUN apk add --no-cache \
    bash \
    curl \
    git \
    unzip \
    libzip-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    libxml2-dev \
    oniguruma-dev \
    icu-dev \
    zlib-dev \
    supervisor \
    vim \
    tzdata \
    shadow \
    autoconf \
    g++ \
    make \
    pcre-dev \
    brotli-dev \
    libstdc++ \
    pkgconfig \
    linux-headers \
    file \
    && docker-php-ext-install \
    pdo_mysql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    intl \
    zip \
    tokenizer \
    xml \
    && pecl install swoole \
    && docker-php-ext-enable swoole

# Opcache optimizado para producción
RUN echo "opcache.enable=1" > /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.validate_timestamps=${OPCACHE_VALIDATE_TIMESTAMPS}" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.memory_consumption=${OPCACHE_MEMORY_CONSUMPTION}" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.interned_strings_buffer=16" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.max_accelerated_files=10000" >> /usr/local/etc/php/conf.d/opcache.ini

# Límites de PHP
RUN echo "memory_limit=${PHP_MEMORY_LIMIT}" > /usr/local/etc/php/conf.d/limits.ini \
    && echo "max_execution_time=${PHP_MAX_EXECUTION_TIME}" >> /usr/local/etc/php/conf.d/limits.ini \
    && echo "upload_max_filesize=${PHP_UPLOAD_MAX_FILESIZE}" >> /usr/local/etc/php/conf.d/limits.ini \
    && echo "post_max_size=${PHP_POST_MAX_SIZE}" >> /usr/local/etc/php/conf.d/limits.ini

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Crear usuario sin privilegios para ejecutar PHP
RUN usermod -u 1000 www-data && groupmod -g 1000 www-data

# Crear directorio de trabajo
WORKDIR /var/www/html

# Copiar aplicación
COPY . /var/www/html

# Copiar configuración de supervisord y script de entrada
COPY .deploy/entrypoint.sh /entrypoint.sh
COPY .deploy/config/supervisor.conf /etc/supervisor/conf.d/supervisor.conf
COPY .deploy/config/crontab /etc/cron.d/laravel

# Permisos
RUN chmod +x /entrypoint.sh \
    && chmod 0644 /etc/cron.d/laravel \
    && crontab /etc/cron.d/laravel

# Entrypoint
ENTRYPOINT ["/entrypoint.sh"]
