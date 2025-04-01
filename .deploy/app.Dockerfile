ARG PHP_VERSION=8.2
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
    npm

# Instalar extensiones de PHP
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

# Supervisord
COPY --from=ochinchina/supervisord:latest /usr/local/bin/supervisord /usr/local/bin/supervisord

# Composer
COPY --from=composer/composer:2 /usr/bin/composer /usr/local/bin/composer

FROM php-system-setup AS app-setup

# Variables
ENV LARAVEL_PATH=/srv/app
WORKDIR $LARAVEL_PATH

# Crear usuario sin privilegios
ARG NON_ROOT_GROUP=app
ARG NON_ROOT_USER=app
RUN addgroup -S $NON_ROOT_GROUP && adduser -S $NON_ROOT_USER -G $NON_ROOT_GROUP
RUN addgroup $NON_ROOT_USER wheel

# Copiar código y configs
COPY . /srv/app
COPY ./.deploy/config/php.ini /usr/local/etc/php/conf.d/local.ini
COPY ./.deploy/entrypoint.sh /entrypoint.sh
COPY ./.deploy/config/supervisor.conf /etc/supervisor/conf.d/supervisord.conf
COPY ./.deploy/config/crontab /etc/crontabs/$NON_ROOT_USER

# Permisos
RUN chmod +x /entrypoint.sh \
    && chown -R $NON_ROOT_USER:$NON_ROOT_GROUP /srv/app \
    && chmod -R 775 /srv/app/storage /srv/app/bootstrap/cache \
    && chmod 777 /usr/sbin/crond \
    && chown -R $NON_ROOT_USER:$NON_ROOT_GROUP /etc/crontabs/$NON_ROOT_USER \
    && setcap cap_setgid=ep /usr/sbin/crond \
    && git config --global --add safe.directory /srv/app

# Cambiar a usuario sin privilegios
USER $NON_ROOT_USER

# Instalar dependencias de Laravel
RUN composer install --prefer-dist --no-dev --no-scripts \
    && rm -rf /home/$NON_ROOT_USER/.composer

# Compilar assets
RUN npm ci && npm run build

# Exponer puerto Laravel interno (para FPM)
EXPOSE 9000

ENTRYPOINT ["sh", "/entrypoint.sh"]