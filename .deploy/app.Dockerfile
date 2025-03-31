FROM php:8.2-fpm

# Argumentos de construcción definidos en el docker-compose.yml
ARG PHP_MEMORY_LIMIT
ARG PHP_MAX_EXECUTION_TIME
ARG PHP_UPLOAD_MAX_FILESIZE
ARG PHP_POST_MAX_SIZE
ARG OPCACHE_VALIDATE_TIMESTAMPS
ARG OPCACHE_MEMORY_CONSUMPTION

# Instalar dependencias
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libzip-dev \
    libicu-dev \
    cron \
    supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Instalar extensiones PHP
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip intl opcache

# Configuración de OPcache para producción
RUN { \
    echo "opcache.enable=1"; \
    echo "opcache.validate_timestamps=${OPCACHE_VALIDATE_TIMESTAMPS}"; \
    echo "opcache.revalidate_freq=0"; \
    echo "opcache.memory_consumption=${OPCACHE_MEMORY_CONSUMPTION}"; \
    echo "opcache.max_accelerated_files=10000"; \
    echo "opcache.max_wasted_percentage=10"; \
    echo "opcache.interned_strings_buffer=16"; \
    echo "opcache.fast_shutdown=1"; \
    } > /usr/local/etc/php/conf.d/opcache.ini

# Configuración de límites PHP
RUN { \
    echo "memory_limit=${PHP_MEMORY_LIMIT}"; \
    echo "max_execution_time=${PHP_MAX_EXECUTION_TIME}"; \
    echo "upload_max_filesize=${PHP_UPLOAD_MAX_FILESIZE}"; \
    echo "post_max_size=${PHP_POST_MAX_SIZE}"; \
    } > /usr/local/etc/php/conf.d/limits.ini

# Instalar Redis
RUN pecl install redis && docker-php-ext-enable redis

# Instalar Swoole para Octane
RUN pecl install swoole
RUN docker-php-ext-enable swoole

# Obtener Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Crear archivo PHP personalizado
RUN echo '[PHP]\ndate.timezone = America/Bogota\nzend.enable_gc = On\nexpose_php = Off\nmax_input_vars = 5000\nsession.cookie_httponly = 1\nsession.cookie_secure = 1\nsession.cookie_samesite = "Lax"\nopcache.enable_cli = 1\nupload_max_filesize = 100M\npost_max_size = 100M\nmemory_limit = 256M\n' > /usr/local/etc/php/conf.d/custom.ini

# Configuración de Supervisor
RUN mkdir -p /etc/supervisor/conf.d
RUN echo '[supervisord]\nnodaemon=true\nuser=root\nlogfile=/var/log/supervisor/supervisord.log\npidfile=/var/run/supervisord.pid\n\n[program:octane]\nprocess_name=%(program_name)s\ncommand=php /var/www/html/artisan octane:start --server=swoole --host=0.0.0.0 --port=8000 --workers=4 --task-workers=2 --max-requests=1000\nautostart=true\nautorestart=true\nstopasgroup=true\nkillasgroup=true\nuser=www-data\nredirect_stderr=true\nstdout_logfile=/var/www/html/storage/logs/octane.log\nstopwaitsecs=60\n\n[program:cron]\ncommand=/usr/sbin/cron -f\nautostart=true\nautorestart=true\nstdout_logfile=/var/log/cron.log\nredirect_stderr=true\n' > /etc/supervisor/conf.d/supervisord.conf

# Crear archivo de crontab
RUN echo '# Laravel Scheduler\n* * * * * cd /var/www/html && php artisan schedule:run >> /var/www/html/storage/logs/cron.log 2>&1\n\n# Optimización diaria (a las 2:00 AM)\n0 2 * * * cd /var/www/html && php artisan optimize >> /var/www/html/storage/logs/cron.log 2>&1\n' > /etc/cron.d/laravel-cron
RUN chmod 0644 /etc/cron.d/laravel-cron && crontab /etc/cron.d/laravel-cron

# Entrypoint script
COPY .deploy/entrypoint.sh /entrypoint.sh || echo '#!/bin/bash\nset -e\ncd /var/www/html\nchown -R www-data:www-data /var/www/html\nchmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache\nif [ "${RUN_MIGRATIONS}" = "true" ]; then\n    php artisan migrate --force\nfi\nif [ "${RUN_SEEDERS}" = "true" ]; then\n    php artisan db:seed --force\nfi\nphp artisan optimize\nphp artisan config:cache\nphp artisan route:cache\nphp artisan view:cache\nexec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf' > /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Configurar directorio de trabajo
WORKDIR /var/www/html

ENTRYPOINT ["/entrypoint.sh"]