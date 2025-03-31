FROM php:8.2-cli

# 1. Instalar dependencias del sistema
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
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip

# 2. Instalar Composer desde contenedor oficial
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 3. Instalar Swoole desde PECL con soporte Brotli
RUN pecl install swoole && docker-php-ext-enable swoole

# 4. Crear directorio de trabajo
WORKDIR /var/www

# 5. Copiar archivos de configuración (desde carpeta `.deploy`)
COPY .deploy/entrypoint.sh /entrypoint.sh
COPY .deploy/config/supervisor.conf /etc/supervisor/conf.d/supervisor.conf
COPY .deploy/config/crontab /etc/cron.d/laravel
COPY .deploy/config/php.ini /usr/local/etc/php/conf.d/php.ini

# 6. Permisos y cron
RUN chmod +x /entrypoint.sh \
    && chmod 0644 /etc/cron.d/laravel \
    && crontab /etc/cron.d/laravel

# 7. Entrypoint
ENTRYPOINT ["/entrypoint.sh"]
