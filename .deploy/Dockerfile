FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Bogota

# Dependencias del sistema
RUN apt-get update && apt-get install -y \
    bash \
    git \
    unzip \
    nano \
    curl \
    gnupg \
    ca-certificates \
    supervisor \
    cron \
    netcat-openbsd \
    libzip-dev \
    libpng-dev \
    libxml2-dev \
    libicu-dev \
    libonig-dev \
    libssl-dev \
    pkg-config \
    libcurl4-openssl-dev \
    autoconf \
    gcc \
    g++ \
    make \
    software-properties-common \
    && add-apt-repository ppa:ondrej/php -y \
    && apt-get update && apt-get install -y \
    php8.2 php8.2-cli php8.2-fpm php8.2-common php8.2-dev \
    php8.2-mysql php8.2-zip php8.2-gd php8.2-mbstring php8.2-curl \
    php8.2-xml php8.2-bcmath php8.2-intl php8.2-readline \
    && pecl install swoole \
    && echo "extension=swoole.so" > /etc/php/8.2/mods-available/swoole.ini \
    && phpenmod swoole \
    && pecl install redis \
    && echo "extension=redis.so" > /etc/php/8.2/mods-available/redis.ini \
    && phpenmod redis \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Composer
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer

# Node.js para compilar assets (opcional si usas Vite/NPM)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# Directorio de trabajo
WORKDIR /var/www/html
COPY . .

# Copia configuración personalizada
COPY .deploy/config/php.ini /etc/php/8.2/fpm/php.ini
COPY .deploy/config/supervisor.conf /etc/supervisord.conf
COPY .deploy/config/crontab /etc/cron.d/laravel
COPY .deploy/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Ajuste de permisos Laravel
RUN chown -R www-data:www-data storage bootstrap/cache && \
    chmod -R 775 storage bootstrap/cache

# Expone el puerto de Octane (Swoole)
EXPOSE 9000

# Entrypoint
CMD ["/entrypoint.sh"]
