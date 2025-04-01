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

# Agregar usuario y grupo
ARG NON_ROOT_GROUP=app
ARG NON_ROOT_USER=app
RUN addgroup -S $NON_ROOT_GROUP && adduser -S $NON_ROOT_USER -G $NON_ROOT_GROUP
RUN addgroup $NON_ROOT_USER wheel

# Copiar y dar permisos a entrypoint como root
COPY ./.deploy/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Supervisord conf
COPY ./.deploy/config/supervisor.conf /etc/supervisor/conf.d/supervisord.conf

# Cron
COPY ./.deploy/config/crontab /etc/crontabs/$NON_ROOT_USER
RUN chmod 777 /usr/sbin/crond \
    && chown -R $NON_ROOT_USER:$NON_ROOT_GROUP /etc/crontabs/$NON_ROOT_USER \
    && setcap cap_setgid=ep /usr/sbin/crond

# App y permisos antes de cambiar de usuario
COPY composer.json composer.lock ./
RUN chown -R $NON_ROOT_USER:$NON_ROOT_GROUP $LARAVEL_PATH

USER $NON_ROOT_USER

# Composer
RUN composer install --prefer-dist --no-scripts --no-dev --no-autoloader
RUN rm -rf /home/$NON_ROOT_USER/.composer

# Copiar el resto del proyecto
COPY --chown=$NON_ROOT_USER:$NON_ROOT_GROUP . $LARAVEL_PATH/

# PHP settings
COPY ./.deploy/config/php.ini /usr/local/etc/php/conf.d/local.ini

# Assets
RUN npm ci && npm run build

EXPOSE 9000

ENTRYPOINT ["sh", "/entrypoint.sh"]