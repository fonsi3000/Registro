FROM php:8.2-fpm-alpine

# Instalar dependencias del sistema
RUN apk add --no-cache linux-headers
RUN apk --no-cache upgrade && \
    apk --no-cache add bash git sudo openssl libxml2-dev oniguruma-dev autoconf gcc g++ make npm freetype-dev libjpeg-turbo-dev libpng-dev libzip-dev

# Instalar extensiones PHP mediante PECL
RUN pecl channel-update pecl.php.net
RUN pecl install pcov swoole
RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install mbstring xml pcntl gd zip sockets pdo pdo_mysql bcmath soap
RUN docker-php-ext-enable mbstring xml gd zip pcov pcntl sockets bcmath pdo pdo_mysql soap swoole

# Instalar extensiones adicionales
RUN docker-php-ext-install pdo pdo_mysql sockets
RUN apk add icu-dev
RUN docker-php-ext-configure intl && docker-php-ext-install mysqli pdo pdo_mysql intl

# Instalar Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Establecer el directorio de trabajo
WORKDIR /app

# Copiar el código de la aplicación
COPY . .

# Instalar dependencias de Composer
RUN composer install
RUN composer require laravel/octane
RUN composer dump-autoload --optimize

# Crear directorio de logs
RUN mkdir -p /app/storage/logs

# Instalar Octane con Swoole
RUN php artisan octane:install --server="swoole"

# Copiar script de entrypoint
COPY .deploy/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:8000 || exit 1

# Exponer puerto
EXPOSE 8000

# Configurar entrypoint y comando por defecto
ENTRYPOINT ["/entrypoint.sh"]
CMD ["php", "artisan", "octane:start", "--server=swoole", "--host=0.0.0.0"]