FROM php:8.2-cli

# Dependencias del sistema
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
    vim \
    cron \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Instalar Swoole (para Octane)
RUN pecl install swoole && docker-php-ext-enable swoole

# Crear directorio de trabajo
WORKDIR /var/www

# Copiar configuraciones
COPY .deploy/entrypoint.sh /entrypoint.sh
COPY .deploy/config/supervisor.conf /etc/supervisor/conf.d/supervisor.conf
COPY .deploy/config/crontab /etc/cron.d/laravel
RUN chmod +x /entrypoint.sh && chmod 0644 /etc/cron.d/laravel && crontab /etc/cron.d/laravel

ENTRYPOINT ["/entrypoint.sh"]