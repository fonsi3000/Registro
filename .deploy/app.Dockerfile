ARG PHP_VERSION=${PHP_VERSION:-8.3}
FROM php:${PHP_VERSION}-fpm-alpine AS php-system-setup

# Establecer zona horaria y variables de entorno
ENV TZ=America/Bogota

# Actualizar repositorios e instalar dependencias del sistema
RUN apk update && apk upgrade && \
    apk add --no-cache \
    curl \
    zip \
    unzip \
    git \
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
    supervisor

# Instalar Node.js más reciente para mejor compatibilidad con Vite
RUN apk add --no-cache nodejs npm && \
    npm install -g npm@latest && \
    npm install -g vite@latest

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

# Asegurar que los directorios existen
RUN mkdir -p /etc/supervisor/conf.d

# Configurar Supervisor (versión modificada sin Caddy)
COPY .deploy/config/supervisor.conf /etc/supervisor/conf.d/supervisord.conf

# Configurar Cron
COPY .deploy/config/crontab /etc/crontabs/root
RUN chmod 0644 /etc/crontabs/root

# Si deseas usar root en lugar de www-data
# (Nota: esto es menos seguro pero seguimos tu preferencia)
RUN sed -i 's/user = www-data/user = root/g' /usr/local/etc/php-fpm.d/www.conf
RUN sed -i 's/group = www-data/group = root/g' /usr/local/etc/php-fpm.d/www.conf

# Primero copiamos solo package.json y package-lock.json para aprovechar el caché de capas
COPY package*.json ./
RUN npm ci || npm install

# Copiamos composer.json y composer.lock para instalar dependencias
COPY composer.json composer.lock ./
RUN composer install --no-scripts --no-autoloader --no-interaction

# Ahora copiamos el resto de la aplicación
COPY . .

# Finalizar instalación de Composer
RUN composer dump-autoload --optimize

# Configurar entrypoint
COPY .deploy/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Configuraciones para Laravel
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV COMPOSER_MEMORY_LIMIT=-1
ENV IGNITION_LOCAL=false
# Solución para problemas de OpenSSL en Node.js 17+
ENV NODE_OPTIONS=--openssl-legacy-provider

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD SCRIPT_NAME=/ping SCRIPT_FILENAME=/ping REQUEST_METHOD=GET cgi-fcgi -bind -connect 127.0.0.1:9000 || exit 1

# Exponer puerto - PHP-FPM
EXPOSE 9000

# Iniciar servicios
ENTRYPOINT ["/entrypoint.sh"]