ARG PHP_VERSION=${PHP_VERSION:-8.2}
FROM php:${PHP_VERSION}-fpm-alpine AS php-system-setup

# Establecer zona horaria
ENV TZ=America/Bogota
ENV CADDY_HOME=/usr/local/caddy

# Instalar dependencias del sistema
RUN apk add --no-cache \
    curl \
    zip \
    unzip \
    git \
    libcap \
    dcron \
    busybox-suid \
    shadow \
    nano \
    supervisor

# Instalar extensiones PHP desde un instalador más confiable
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

# Instalar supervisord
COPY --from=ochinchina/supervisord:latest /usr/local/bin/supervisord /usr/local/bin/supervisord

# Instalar Caddy
COPY --from=caddy:2.7.6 /usr/bin/caddy /usr/local/bin/caddy
RUN setcap 'cap_net_bind_service=+ep' /usr/local/bin/caddy

# Instalar composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Segunda etapa para la configuración de la aplicación
FROM php-system-setup AS app-setup

# Directorio de trabajo
ENV LARAVEL_PATH=/var/www/html
WORKDIR $LARAVEL_PATH

# Configurar PHP-FPM
COPY .deploy/config/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf
COPY .deploy/config/php.ini /usr/local/etc/php/conf.d/custom.ini

# Configurar Caddy
COPY .deploy/config/Caddyfile /etc/caddy/Caddyfile

# Configurar Supervisor
COPY .deploy/config/supervisor.conf /etc/supervisor/conf.d/supervisord.conf

# Configurar Cron
COPY .deploy/config/crontab /etc/crontabs/www-data
RUN chmod 0644 /etc/crontabs/www-data

# Configurar usuario www-data
RUN usermod -u 1000 www-data && \
    groupmod -g 1000 www-data

# Configurar entrypoint
COPY .deploy/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD SCRIPT_NAME=/ping SCRIPT_FILENAME=/ping REQUEST_METHOD=GET cgi-fcgi -bind -connect 127.0.0.1:9000 || exit 1

# Exponer puertos - PHP-FPM y Caddy
EXPOSE 9000 2019

# Iniciar servicios
ENTRYPOINT ["/entrypoint.sh"]