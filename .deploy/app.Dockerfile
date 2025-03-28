ARG PHP_VERSION=${PHP_VERSION:-8.2}
FROM php:${PHP_VERSION}-fpm-alpine AS php-system-setup

# Establecer zona horaria y variables de entorno
ENV TZ=America/Bogota
ENV CADDY_HOME=/usr/local/caddy

# Actualizar repositorios e instalar dependencias del sistema
RUN apk update && apk upgrade && \
    apk add --no-cache \
    curl \
    zip \
    unzip \
    git \
    libcap \
    dcron \
    busybox-suid \
    shadow \
    libzip-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libxml2-dev \
    oniguruma-dev \
    linux-headers \
    tzdata \
    nano \
    supervisor \
    # Agregar Node.js y npm para compilación de assets
    nodejs \
    npm

# Instalar extensiones PHP usando el instalador oficial
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/bin/
RUN install-php-extensions \
    intl \
    bcmath \
    gd \
    pdo_mysql \
    mysqli \
    opcache \
    redis \
    exif \
    pcntl \
    zip \
    mbstring

# Instalar supervisord desde imagen oficial
COPY --from=ochinchina/supervisord:latest /usr/local/bin/supervisord /usr/local/bin/supervisord

# Instalar Caddy desde imagen oficial
COPY --from=caddy:2.7.6 /usr/bin/caddy /usr/local/bin/caddy
RUN setcap 'cap_net_bind_service=+ep' /usr/local/bin/caddy

# Instalar Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Segunda etapa para la configuración de la aplicación
FROM php-system-setup AS app-setup

# Configurar directorio de trabajo
ENV LARAVEL_PATH=/var/www/html
WORKDIR $LARAVEL_PATH

# Configurar PHP-FPM
COPY .deploy/config/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf
COPY .deploy/config/php.ini /usr/local/etc/php/conf.d/custom.ini

# Configurar Caddy
RUN mkdir -p /etc/caddy
COPY .deploy/config/Caddyfile /etc/caddy/Caddyfile

# Asegurar que los directorios existen
RUN mkdir -p /etc/supervisor/conf.d

# Configurar Supervisor
COPY .deploy/config/supervisor.conf /etc/supervisor/conf.d/supervisord.conf

# Configurar Cron
COPY .deploy/config/crontab /etc/crontabs/www-data
RUN chmod 0644 /etc/crontabs/www-data

# Configurar usuario www-data para que coincida con el ID del host
RUN usermod -u 1000 www-data && \
    groupmod -g 1000 www-data

# Configurar entrypoint
COPY .deploy/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Configuraciones para Laravel 11
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV COMPOSER_MEMORY_LIMIT=-1
ENV IGNITION_LOCAL=false

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD SCRIPT_NAME=/ping SCRIPT_FILENAME=/ping REQUEST_METHOD=GET cgi-fcgi -bind -connect 127.0.0.1:9000 || exit 1

# Exponer puertos - PHP-FPM y Caddy
EXPOSE 9000 2019

# Iniciar servicios
ENTRYPOINT ["/entrypoint.sh"]