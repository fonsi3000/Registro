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

# Establecer permisos del cron y php.ini
COPY ./.deploy/config/crontab /etc/crontabs/$NON_ROOT_USER
COPY ./.deploy/config/php.ini /usr/local/etc/php/conf.d/local.ini
COPY ./.deploy/config/supervisor.conf /etc/supervisor/conf.d/supervisord.conf

RUN chmod 777 /usr/sbin/crond \
    && chown -R $NON_ROOT_USER:$NON_ROOT_GROUP /etc/crontabs/$NON_ROOT_USER \
    && setcap cap_setgid=ep /usr/sbin/crond

# Copiar entrypoint
COPY ./.deploy/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copiar archivos de la aplicación
COPY --chown=$NON_ROOT_USER:$NON_ROOT_GROUP . $LARAVEL_PATH/

# Asegurarse que el directorio .git es seguro
RUN git config --global --add safe.directory $LARAVEL_PATH

# Instalar dependencias PHP sin scripts ni dev como usuario app
USER $NON_ROOT_USER
RUN composer install --prefer-dist --no-scripts --no-dev --no-autoloader
RUN rm -rf /home/$NON_ROOT_USER/.composer

# Construcción de assets
RUN npm ci && npm run build

# Volver a root para configurar permisos finales
USER root

# Configurar permisos correctos para directorios críticos
RUN mkdir -p $LARAVEL_PATH/storage/logs \
    && mkdir -p $LARAVEL_PATH/storage/framework/cache \
    && mkdir -p $LARAVEL_PATH/storage/framework/sessions \
    && mkdir -p $LARAVEL_PATH/storage/framework/views \
    && mkdir -p $LARAVEL_PATH/bootstrap/cache \
    && chown -R $NON_ROOT_USER:$NON_ROOT_GROUP $LARAVEL_PATH \
    && chmod -R 775 $LARAVEL_PATH/storage $LARAVEL_PATH/bootstrap/cache

# Cambiar a usuario app para la ejecución
USER $NON_ROOT_USER

# Exponer puerto de Laravel
EXPOSE 9000

ENTRYPOINT ["sh", "/entrypoint.sh"]