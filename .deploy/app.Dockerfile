# Usar una imagen base de Ubuntu 22.04
FROM ubuntu:22.04

# Configurar variables de entorno básicas
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Bogota
ENV OCTANE_SERVER=swoole

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
    php8.2-redis \
    php8.2-dev \
    php8.2-swoole

# Configurar OPcache para mejor rendimiento
RUN echo "opcache.enable=1" >> /etc/php/8.2/cli/conf.d/10-opcache.ini && \
    echo "opcache.memory_consumption=128" >> /etc/php/8.2/cli/conf.d/10-opcache.ini && \
    echo "opcache.interned_strings_buffer=8" >> /etc/php/8.2/cli/conf.d/10-opcache.ini && \
    echo "opcache.max_accelerated_files=10000" >> /etc/php/8.2/cli/conf.d/10-opcache.ini && \
    echo "opcache.validate_timestamps=0" >> /etc/php/8.2/cli/conf.d/10-opcache.ini && \
    echo "opcache.save_comments=1" >> /etc/php/8.2/cli/conf.d/10-opcache.ini && \
    echo "opcache.fast_shutdown=1" >> /etc/php/8.2/cli/conf.d/10-opcache.ini

# Configurar PHP para mejor rendimiento con Octane
RUN echo "memory_limit=512M" >> /etc/php/8.2/cli/conf.d/99-custom.ini && \
    echo "max_execution_time=60" >> /etc/php/8.2/cli/conf.d/99-custom.ini

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

# Copiar composer.json y composer.lock primero para aprovechar la cache de capas
COPY composer.json composer.lock ./

# Instalar dependencias PHP sin los archivos del proyecto (para aprovechar la cache)
RUN composer install --no-scripts --no-autoloader --prefer-dist

# Copiar toda la aplicación ahora
COPY . .

# Instalar Octane explícitamente
RUN composer require laravel/octane --with-all-dependencies

# Instalar Octane y seleccionar Swoole como servidor
RUN php artisan octane:install --server=swoole --force

# Verificar y corregir el registro del proveedor de servicios de Octane
RUN php artisan list | grep octane || echo "Octane no está registrado correctamente; registrando manualmente"
RUN if ! php artisan list | grep -q octane; then \
    echo "class_exists('\Laravel\Octane\OctaneServiceProvider') || exit(1);" | php && \
    sed -i "/App\\\\Providers\\\\RouteServiceProvider::class,/a \        Laravel\\\\Octane\\\\OctaneServiceProvider::class," config/app.php; \
    fi

# Verificar después de registro manual
RUN php artisan list | grep octane

# Completar la instalación de composer
RUN composer dump-autoload --optimize

# Configurar la aplicación
RUN php artisan package:discover --ansi
RUN php artisan config:clear --no-interaction
RUN php artisan view:clear --no-interaction
RUN php artisan route:clear --no-interaction

# Instalar dependencias de Node.js
RUN npm ci --no-audit --prefer-offline || npm install --no-audit --prefer-offline

# Compilar assets
RUN npm run build || echo "Asset compilation failed, continuing anyway"

# Configurar permisos finales
RUN chown -R www-data:www-data /var/www/html && \
    find /var/www/html/storage -type d -exec chmod 775 {} \; && \
    find /var/www/html/storage -type f -exec chmod 664 {} \; && \
    chmod -R 775 /var/www/html/bootstrap/cache

# Limpiar caché de paquetes
RUN apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configurar entrypoint
COPY .deploy/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8000 || exit 1

# Exponer puerto para Octane
EXPOSE 8000

# Iniciar servicios
ENTRYPOINT ["/entrypoint.sh"]