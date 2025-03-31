ARG PHP_VERSION=${PHP_VERSION:-8.2}
FROM php:${PHP_VERSION}-fpm-alpine AS php-system-setup

# Install system dependencies
RUN apk add --no-cache dcron busybox-suid libcap curl zip unzip git supervisor bash libpng-dev oniguruma-dev libxml2-dev icu-dev

# Install PHP extensions
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/bin/
RUN install-php-extensions intl bcmath gd pdo_mysql opcache redis uuid exif pcntl zip swoole

# Install supervisord implementation
COPY --from=ochinchina/supervisord:latest /usr/local/bin/supervisord /usr/local/bin/supervisord

# Install composer (corregido)
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

FROM php-system-setup AS app-setup

# Set working directory
ENV LARAVEL_PATH=/var/www/html
WORKDIR $LARAVEL_PATH

# Add non-root user: 'app'
ARG NON_ROOT_GROUP=${NON_ROOT_GROUP:-www-data}
ARG NON_ROOT_USER=${NON_ROOT_USER:-www-data}
RUN addgroup -S $NON_ROOT_GROUP && adduser -S $NON_ROOT_USER -G $NON_ROOT_GROUP
RUN addgroup $NON_ROOT_USER wheel

# Configuración de OPcache para producción
ARG OPCACHE_VALIDATE_TIMESTAMPS
ARG OPCACHE_MEMORY_CONSUMPTION
RUN { \
    echo "opcache.enable=1"; \
    echo "opcache.validate_timestamps=${OPCACHE_VALIDATE_TIMESTAMPS}"; \
    echo "opcache.revalidate_freq=0"; \
    echo "opcache.memory_consumption=${OPCACHE_MEMORY_CONSUMPTION}"; \
    echo "opcache.max_accelerated_files=10000"; \
    echo "opcache.max_wasted_percentage=10"; \
    echo "opcache.interned_strings_buffer=16"; \
    echo "opcache.fast_shutdown=1"; \
    echo "opcache.enable_cli=1"; \
    echo "opcache.jit_buffer_size=100M"; \
    echo "opcache.jit=1235"; \
    } > /usr/local/etc/php/conf.d/opcache.ini

# Configuración de límites PHP
ARG PHP_MEMORY_LIMIT
ARG PHP_MAX_EXECUTION_TIME
ARG PHP_UPLOAD_MAX_FILESIZE
ARG PHP_POST_MAX_SIZE
RUN { \
    echo "memory_limit=${PHP_MEMORY_LIMIT}"; \
    echo "max_execution_time=${PHP_MAX_EXECUTION_TIME}"; \
    echo "upload_max_filesize=${PHP_UPLOAD_MAX_FILESIZE}"; \
    echo "post_max_size=${PHP_POST_MAX_SIZE}"; \
    } > /usr/local/etc/php/conf.d/limits.ini

# Set cron job
COPY ./.deploy/crontab /etc/crontabs/$NON_ROOT_USER
RUN chmod 777 /usr/sbin/crond
RUN chown -R $NON_ROOT_USER:$NON_ROOT_GROUP /etc/crontabs/$NON_ROOT_USER && setcap cap_setgid=ep /usr/sbin/crond

# Supervisor configuration
RUN mkdir -p /etc/supervisor/conf.d
COPY ./.deploy/supervisor.conf /etc/supervisor/conf.d/supervisord.conf

# PHP custom configuration
COPY ./.deploy/php.ini /usr/local/etc/php/conf.d/php.ini

# Copy app with proper ownership
COPY --chown=$NON_ROOT_USER:$NON_ROOT_GROUP . $LARAVEL_PATH/

# Set any ENVs
ARG APP_KEY=${APP_KEY}
ARG APP_NAME=${APP_NAME}
ARG APP_URL=${APP_URL}
ARG APP_ENV=${APP_ENV}
ARG APP_DEBUG=${APP_DEBUG}
ARG APP_TIMEZONE=${APP_TIMEZONE}
ARG APP_LOCALE=${APP_LOCALE}
ARG APP_FALLBACK_LOCALE=${APP_FALLBACK_LOCALE}

ARG LOG_CHANNEL=${LOG_CHANNEL}
ARG LOG_LEVEL=${LOG_LEVEL}

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
ARG SESSION_SECURE_COOKIE=${SESSION_SECURE_COOKIE}
ARG SESSION_COOKIE_HTTPONLY=${SESSION_COOKIE_HTTPONLY}

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
ARG MAIL_FROM_NAME=${MAIL_FROM_NAME}

ARG SANCTUM_STATEFUL_DOMAINS=${SANCTUM_STATEFUL_DOMAINS}
ARG SESSION_DOMAIN=${SESSION_DOMAIN}

ARG OCTANE_SERVER=${OCTANE_SERVER}

ARG RUN_MIGRATIONS=${RUN_MIGRATIONS}
ARG RUN_SEEDERS=${RUN_SEEDERS}

# Setup for Laravel Octane
RUN mkdir -p $LARAVEL_PATH/storage/logs
RUN chown -R $NON_ROOT_USER:$NON_ROOT_GROUP $LARAVEL_PATH/storage
RUN chmod -R 775 $LARAVEL_PATH/storage

# Start app
EXPOSE 8000

# Copy and set entrypoint
COPY ./.deploy/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]