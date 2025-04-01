ARG PHP_VERSION=${PHP_VERSION:-8.2}
FROM php:${PHP_VERSION}-fpm-alpine AS php-system-setup

# Instalar dependencias del sistema
RUN apk add --no-cache \
    dcron \
    busybox-suid \
    libcap \
    curl \
    zip \
    unzip \
    git \
    nodejs \
    npm \
    shadow \
    supervisor \
    bash

# Instalar extensiones PHP necesarias
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/bin/
RUN install-php-extensions \
    intl \
    bcmath \
    gd \
    pdo_mysql \
    pdo_pgsql \
    opcache \
    redis \
    uuid \
    exif \
    pcntl \
    zip

# Instalar Composer
COPY --from=composer/composer:2 /usr/bin/composer /usr/local/bin/composer

# Instalar supervisord
COPY --from=ochinchina/supervisord:latest /usr/local/bin/supervisord /usr/local/bin/supervisord

# Segunda fase de la build
FROM php-system-setup AS app-setup

ENV LARAVEL_PATH=/srv/app
WORKDIR $LARAVEL_PATH

# Crear usuario no root
ARG NON_ROOT_GROUP=${NON_ROOT_GROUP:-app}
ARG NON_ROOT_USER=${NON_ROOT_USER:-app}
RUN addgroup -S $NON_ROOT_GROUP && adduser -S $NON_ROOT_USER -G $NON_ROOT_GROUP && \
    mkdir -p /run/php && chown -R $NON_ROOT_USER:$NON_ROOT_GROUP /run/php

# Copiar cron
COPY ./.deploy/config/crontab /etc/crontabs/$NON_ROOT_USER
RUN chmod 600 /etc/crontabs/$NON_ROOT_USER && chown -R $NON_ROOT_USER:$NON_ROOT_GROUP /etc/crontabs/$NON_ROOT_USER

# Copiar configuración PHP
COPY ./.deploy/config/php.ini /usr/local/etc/php/conf.d/local.ini

# Copiar Composer files e instalar dependencias
COPY composer.json composer.lock ./
RUN chown -R $NON_ROOT_USER:$NON_ROOT_GROUP $LARAVEL_PATH

USER $NON_ROOT_USER
RUN git config --global --add safe.directory "$LARAVEL_PATH" && \
    composer install --prefer-dist --no-scripts --no-dev --no-autoloader && \
    rm -rf /home/$NON_ROOT_USER/.composer

# Copiar el resto del proyecto
COPY --chown=$NON_ROOT_USER:$NON_ROOT_GROUP . $LARAVEL_PATH/

# Build de assets
RUN npm ci && npm run build

# Asignar permisos correctos
RUN mkdir -p storage/logs bootstrap/cache && chmod -R ug+rwX storage bootstrap/cache

# Copiar scripts de arranque
COPY ./.deploy/entrypoint.sh /entrypoint.sh
COPY ./.deploy/config/supervisor.conf /etc/supervisor/conf.d/supervisord.conf
RUN chmod +x /entrypoint.sh

# Exponer el puerto interno de Laravel
EXPOSE 9000

ENTRYPOINT ["/entrypoint.sh"]
