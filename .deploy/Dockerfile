FROM ubuntu:22.04

# Configuración de variables de entorno
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Bogota

# Instalar dependencias del sistema en una sola capa
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y bash git sudo openssh-client \
    libxml2-dev libonig-dev autoconf gcc g++ make \
    libfreetype6-dev libjpeg-turbo8-dev libpng-dev libzip-dev \
    curl unzip nano software-properties-common nginx supervisor cron && \
    # Instalar Node.js
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    # Instalar PHP y extensiones
    add-apt-repository ppa:ondrej/php -y && \
    apt-get update && \
    apt-get install -y php8.2 php8.2-cli php8.2-common \
    php8.2-mysql php8.2-zip php8.2-gd php8.2-mbstring php8.2-curl php8.2-xml php8.2-bcmath \
    php8.2-intl php8.2-readline php8.2-pcov php8.2-dev php8.2-redis && \
    # Instalar Swoole para Octane
    pecl install swoole && \
    echo "extension=swoole.so" > /etc/php/8.2/mods-available/swoole.ini && \
    phpenmod swoole && \
    # Instalar Composer
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    # Limpiar cache
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configurar OPcache para mejorar rendimiento
RUN echo "opcache.enable=1" >> /etc/php/8.2/cli/conf.d/10-opcache.ini && \
    echo "opcache.memory_consumption=128" >> /etc/php/8.2/cli/conf.d/10-opcache.ini && \
    echo "opcache.interned_strings_buffer=8" >> /etc/php/8.2/cli/conf.d/10-opcache.ini && \
    echo "opcache.max_accelerated_files=4000" >> /etc/php/8.2/cli/conf.d/10-opcache.ini && \
    echo "opcache.validate_timestamps=0" >> /etc/php/8.2/cli/conf.d/10-opcache.ini && \
    echo "opcache.fast_shutdown=1" >> /etc/php/8.2/cli/conf.d/10-opcache.ini

# Crear usuario no root para seguridad
RUN groupadd -g 1000 www && \
    useradd -u 1000 -ms /bin/bash -g www www

# Configurar directorio de trabajo
WORKDIR /var/www/html

# Configurar Nginx para trabajar con Octane
COPY ./.deploy/config/nginx.conf /etc/nginx/sites-available/default
RUN ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

# Configurar Supervisor para gestionar Octane
COPY ./.deploy/config/supervisor.conf /etc/supervisor/conf.d/supervisord.conf

# Configurar Cron
COPY ./.deploy/config/crontab /etc/cron.d/laravel-cron
RUN chmod 0644 /etc/cron.d/laravel-cron && \
    echo "" >> /etc/cron.d/laravel-cron && \
    crontab /etc/cron.d/laravel-cron

# Copiar código de la aplicación
COPY --chown=www:www . .

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

# Establecer permisos necesarios para Laravel
RUN chown -R www:www /var/www/html \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Health check apuntando al puerto de Nginx
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:9090/ || exit 1

# Configurar entrypoint
COPY ./.deploy/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Exponer puerto de Nginx
EXPOSE 9090

# Iniciar servicios
ENTRYPOINT ["/entrypoint.sh"]