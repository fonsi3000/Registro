ARG PHP_VERSION=${PHP_VERSION:-8.2}
FROM php:${PHP_VERSION}-fpm-alpine AS php-system-setup

# Install system dependencies
RUN apk add --no-cache \
    dcron \
    busybox-suid \
    libcap \
    curl \
    zip \
    unzip \
    git \
    nodejs \
    npm

# Install PHP extensions
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

# Install supervisord
COPY --from=ochinchina/supervisord:latest /usr/local/bin/supervisord /usr/local/bin/supervisord

# Install composer
COPY --from=composer/composer:2 /usr/bin/composer /usr/local/bin/composer

FROM php-system-setup AS app-setup

ENV LARAVEL_PATH=/srv/app
WORKDIR $LARAVEL_PATH

# Crear usuario no root
ARG NON_ROOT_GROUP=app
ARG NON_ROOT_USER=app
RUN addgroup -S $NON_ROOT_GROUP && adduser -S $NON_ROOT_USER -G $NON_ROOT_GROUP
RUN addgroup $NON_ROOT_USER wheel

# Copiar archivos primero como root para asignar permisos
COPY . $LARAVEL_PATH/

# Asignar permisos y propiedad antes de cambiar a user
RUN chown -R $NON_ROOT_USER:$NON_ROOT_GROUP $LARAVEL_PATH \
    && chmod -R ug+rwX storage bootstrap/cache \
    && git config --global --add safe.directory /srv/app

# Establecer permisos del cron y php.ini
COPY ./.deploy/config/crontab /etc/crontabs/$NON_ROOT_USER
COPY ./.deploy/config/php.ini /usr/local/etc/php/conf.d/local.ini
COPY ./.deploy/config/supervisor.conf /etc/supervisor/conf.d/supervisord.conf

RUN chmod 777 /usr/sbin/crond \
    && chown -R $NON_ROOT_USER:$NON_ROOT_GROUP /etc/crontabs/$NON_ROOT_USER \
    && setcap cap_setgid=ep /usr/sbin/crond

# Cambiar a usuario app
USER $NON_ROOT_USER

# Instalar dependencias PHP sin scripts ni dev
COPY composer.json composer.lock ./
RUN composer install --prefer-dist --no-scripts --no-dev --no-autoloader
RUN rm -rf /home/$NON_ROOT_USER/.composer

# Construcción de assets
RUN npm ci && npm run build

# Exponer puerto de Laravel
EXPOSE 9000

# Copiar entrypoint
COPY --chown=$NON_ROOT_USER:$NON_ROOT_GROUP ./.deploy/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["sh", "/entrypoint.sh"]