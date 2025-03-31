# Dockerfile para app Laravel con Octane + Swoole en Alpine
FROM php:8.2-cli-alpine

# Instalar dependencias del sistema
RUN apk add --no-cache \
    bash \
    libpng-dev \
    libjpeg-turbo-dev \
    libwebp-dev \
    libxpm-dev \
    freetype-dev \
    oniguruma-dev \
    libxml2-dev \
    zip \
    unzip \
    curl \
    git \
    supervisor \
    libzip-dev \
    zlib-dev \
    vim \
    brotli-dev \
    icu-dev \
    tzdata \
    busybox-suid \
    shadow \
    openrc \
    libgcc \
    libstdc++ \
    mysql-client \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath zip intl opcache

# Instalar GD
RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg \
    --with-webp \
    --with-xpm \
    && docker-php-ext-install -j$(nproc) gd

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Instalar Swoole sin soporte Brotli
RUN pecl install swoole \
    && docker-php-ext-enable swoole

# Crear usuario de app
RUN addgroup -g 1000 app && \
    adduser -D -G app -u 1000 app

# Crear directorio de trabajo
WORKDIR /var/www/html

# Copiar archivos de configuración
COPY .deploy/entrypoint.sh /entrypoint.sh
COPY .deploy/config/supervisor.conf /etc/supervisor/conf.d/supervisor.conf
COPY .deploy/config/crontab /etc/crontabs/root

RUN chmod +x /entrypoint.sh && chmod 0644 /etc/crontabs/root

USER app

ENTRYPOINT ["/entrypoint.sh"]