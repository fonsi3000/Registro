FROM php:8.2-fpm-alpine

# Definimos la zona horaria
ENV TZ=America/Bogota
# Carpeta donde se instalará Caddy
ENV CADDY_HOME /usr/local/caddy

# Actualizamos los repositorios e instalamos dependencias esenciales
RUN apk update && apk upgrade && \
    apk add --no-cache \
    git \
    curl \
    zip \
    unzip

# Instalamos dependencias para extensiones PHP
RUN apk add --no-cache \
    libzip-dev \
    libpng-dev \
    libxml2-dev \
    freetype-dev \
    libjpeg-turbo-dev \
    oniguruma-dev \
    linux-headers \
    tzdata

# Instalamos herramientas de desarrollo PHP
RUN apk add --no-cache $PHPIZE_DEPS

# Instalamos utilidades del sistema
RUN apk add --no-cache \
    shadow \
    nano \
    supervisor

# Instalamos cron (usamos busybox en lugar de dcron)
RUN apk add --no-cache busybox-initscripts

# Instalamos Node.js
RUN apk add --no-cache nodejs npm

# Configuramos e instalamos extensiones PHP
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j$(nproc) \
    pdo_mysql \
    mysqli \
    zip \
    exif \
    pcntl \
    bcmath \
    gd \
    opcache \
    intl \
    mbstring

# Instalamos Redis via PECL
RUN pecl install redis && \
    docker-php-ext-enable redis

# Instalamos Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Configuramos el usuario www-data
RUN usermod -u 1000 www-data && \
    groupmod -g 1000 www-data

# Instalar Caddy
RUN mkdir -p ${CADDY_HOME} && \
    cd /tmp && \
    wget -O caddy.tar.gz "https://github.com/caddyserver/caddy/releases/download/v2.7.6/caddy_2.7.6_linux_amd64.tar.gz" && \
    tar -xzf caddy.tar.gz && \
    mv caddy ${CADDY_HOME}/ && \
    rm -rf caddy.tar.gz && \
    ln -sf ${CADDY_HOME}/caddy /usr/local/bin/caddy && \
    caddy version

# Configuramos PHP-FPM - La configuración viene del volumen
COPY .deploy/config/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf
COPY .deploy/config/php.ini /usr/local/etc/php/conf.d/custom.ini

# Configuramos Caddy
COPY .deploy/config/Caddyfile /etc/caddy/Caddyfile

# Configuramos Supervisor para gestionar PHP-FPM, Caddy y colas
COPY .deploy/config/supervisor.conf /etc/supervisor/conf.d/supervisord.conf

# Configuramos Cron usando busybox
COPY .deploy/config/crontab /etc/crontabs/www-data
RUN chmod 0644 /etc/crontabs/www-data

# Configuramos directorio de trabajo
WORKDIR /var/www/html

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD SCRIPT_NAME=/ping SCRIPT_FILENAME=/ping REQUEST_METHOD=GET cgi-fcgi -bind -connect 127.0.0.1:9000 || exit 1

# Configuramos entrypoint
COPY .deploy/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Exponemos puertos - PHP-FPM y Caddy
EXPOSE 9000 2019

# Iniciamos servicios
ENTRYPOINT ["/entrypoint.sh"]