FROM php:8.2-fpm

# Instala dependencias del sistema y PHP, incluyendo Swoole y Redis
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    unzip \
    nano \
    libzip-dev \
    libpng-dev \
    libxml2-dev \
    libicu-dev \
    libonig-dev \
    libssl-dev \
    pkg-config \
    libcurl4-openssl-dev \
    supervisor \
    cron \
    bash \
    gnupg \
    netcat \
    autoconf \
    gcc \
    g++ \
    make \
    && pecl install redis \
    && pecl install swoole-5.0.3 \
    && docker-php-ext-enable redis swoole \
    && docker-php-ext-install \
    pdo \
    pdo_mysql \
    mbstring \
    zip \
    exif \
    pcntl \
    intl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Instala Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Establece el directorio de trabajo
WORKDIR /var/www/html

# Copia el código fuente del proyecto
COPY . .

# Asigna permisos adecuados
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Configuración PHP, supervisor y cron
COPY .deploy/config/php.ini /usr/local/etc/php/php.ini
COPY .deploy/config/supervisor.conf /etc/supervisord.conf
COPY .deploy/config/crontab /etc/cron.d/laravel
RUN chmod 0644 /etc/cron.d/laravel && crontab /etc/cron.d/laravel

# Script de entrada
COPY .deploy/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Puerto expuesto por Octane/Swoole
EXPOSE 9000

# Comando por defecto
CMD ["/entrypoint.sh"]
