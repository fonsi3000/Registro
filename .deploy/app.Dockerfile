# Usar una imagen base de Ubuntu 22.04
FROM ubuntu:22.04

# Configurar variables de entorno básicas
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Bogota

# Set any ENVs
ARG APP_KEY=${APP_KEY}
ARG APP_NAME=${APP_NAME}
ARG APP_URL=${APP_URL}
ARG APP_ENV=${APP_ENV}
ARG APP_DEBUG=${APP_DEBUG}

ARG LOG_CHANNEL=${LOG_CHANNEL}

ARG DB_CONNECTION=${DB_CONNECTION}
ARG DB_HOST=${DB_HOST}
ARG DB_PORT=${DB_PORT}
ARG DB_DATABASE=${DB_DATABASE}
ARG DB_USERNAME=${DB_USERNAME}
ARG DB_PASSWORD=${DB_PASSWORD}

ARG BROADCAST_DRIVER=${BROADCAST_DRIVER}
ARG CACHE_DRIVER=${CACHE_DRIVER}
ARG QUEUE_CONNECTION=${QUEUE_CONNECTION}
ARG SESSION_DRIVER=${SESSION_DRIVER}
ARG SESSION_LIFETIME=${SESSION_LIFETIME}

ARG REDIS_HOST=${REDIS_HOST}
ARG REDIS_PASSWORD=${REDIS_PASSWORD}
ARG REDIS_PORT=${REDIS_PORT}

ARG MAIL_MAILER=${MAIL_MAILER}
ARG MAIL_HOST=${MAIL_HOST}
ARG MAIL_PORT=${MAIL_PORT}
ARG MAIL_USERNAME=${MAIL_USERNAME}
ARG MAIL_PASSWORD=${MAIL_PASSWORD}
ARG MAIL_ENCRYPTION=${MAIL_ENCRYPTION}
ARG MAIL_FROM_ADDRESS=${MAIL_FROM_ADDRESS}
ARG MAIL_FROM_NAME=${APP_NAME}

ARG PUSHER_APP_ID=${PUSHER_APP_ID}
ARG PUSHER_APP_KEY=${PUSHER_APP_KEY}
ARG PUSHER_APP_SECRET=${PUSHER_APP_SECRET}
ARG PUSHER_APP_CLUSTER=${PUSHER_APP_CLUSTER}

# Instalar dependencias del sistema
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    bash \
    git \
    sudo \
    openssh-client \
    libxml2-dev \
    libonig-dev \
    autoconf \
    gcc \
    g++ \
    make \
    libfreetype6-dev \
    libjpeg-turbo8-dev \
    libpng-dev \
    libzip-dev \
    curl \
    unzip \
    nano \
    software-properties-common \
    supervisor \
    cron

# Instalar Node.js 18.x
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# Agregar el repositorio de PHP 8.2 e instalar PHP y extensiones necesarias
RUN add-apt-repository ppa:ondrej/php -y && \
    apt-get update && \
    apt-get install -y \
    php8.2 \
    php8.2-fpm \
    php8.2-cli \
    php8.2-common \
    php8.2-mysql \
    php8.2-zip \
    php8.2-gd \
    php8.2-mbstring \
    php8.2-curl \
    php8.2-xml \
    php8.2-bcmath \
    php8.2-intl \
    php8.2-readline \
    php8.2-redis

# Configurar PHP con tu archivo php.ini personalizado
COPY .deploy/config/php.ini /etc/php/8.2/cli/conf.d/99-custom.ini
COPY .deploy/config/php.ini /etc/php/8.2/fpm/conf.d/99-custom.ini

# Crear directorios necesarios para PHP-FPM
RUN mkdir -p /run/php && \
    chmod 755 /run/php

# Configurar PHP-FPM
COPY .deploy/config/php-fpm.conf /etc/php/8.2/fpm/pool.d/www.conf
RUN sed -i 's/listen = \/run\/php\/php8.2-fpm.sock/listen = 0.0.0.0:9000/g' /etc/php/8.2/fpm/pool.d/www.conf && \
    sed -i 's|error_log = \/var\/log\/php8.2-fpm.log|error_log = \/var\/www\/html\/storage\/logs\/php-fpm.log|g' /etc/php/8.2/fpm/php-fpm.conf && \
    sed -i 's|pid = /run/php/php8.2-fpm.pid|pid = /run/php-fpm.pid|g' /etc/php/8.2/fpm/php-fpm.conf

# Configurar Supervisor
RUN mkdir -p /etc/supervisor/conf.d
COPY .deploy/config/supervisor.conf /etc/supervisor/conf.d/supervisord.conf

# Configurar cron
COPY .deploy/config/crontab /etc/cron.d/laravel-cron
RUN chmod 0644 /etc/cron.d/laravel-cron && \
    echo "" >> /etc/cron.d/laravel-cron

# Instalar Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Establecer el directorio de trabajo
WORKDIR /var/www/html

# Copiar primero solo los archivos de composer y package.json para aprovechar la caché
COPY composer.json composer.lock ./
COPY package*.json ./

# Instalar dependencias PHP (sin ejecutar scripts)
RUN composer install --no-dev --no-scripts --no-interaction

# Ahora copiar toda la aplicación (incluyendo el archivo artisan)
COPY . .

# Después de copiar la aplicación completa, ejecutar los comandos de artisan
RUN composer dump-autoload --optimize --no-dev && \
    php artisan package:discover --ansi || true

# Instalar dependencias de Node.js
RUN npm ci || npm install

# Compilar assets
RUN npm run build || echo "Asset compilation failed, continuing anyway"

# Configurar permisos (establecidos directamente en el Dockerfile)
RUN mkdir -p /var/www/html/storage/logs /var/www/html/bootstrap/cache && \
    touch /var/www/html/storage/logs/laravel.log && \
    touch /var/www/html/storage/logs/php-fpm.log && \
    chown -R www-data:www-data /var/www/html && \
    find /var/www/html/storage -type d -exec chmod 775 {} \; && \
    find /var/www/html/storage -type f -exec chmod 664 {} \; && \
    chmod -R 775 /var/www/html/bootstrap/cache

# Configurar entrypoint
COPY .deploy/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD ps aux | grep php-fpm | grep -v grep || exit 1

# Exponer puerto - PHP-FPM
EXPOSE 9000

# Iniciar servicios
ENTRYPOINT ["/entrypoint.sh"]