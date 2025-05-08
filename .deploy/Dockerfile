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
    libbrotli-dev \
    pkg-config \
    libcurl4-openssl-dev \
    autoconf \
    gcc \
    g++ \
    make \
    software-properties-common

# Repositorio PHP Ondrej
RUN add-apt-repository ppa:ondrej/php -y && \
    apt-get update && \
    apt-get install -y \
    php8.2 php8.2-cli php8.2-fpm php8.2-common php8.2-dev \
    php8.2-mysql php8.2-zip php8.2-gd php8.2-mbstring php8.2-curl \
    php8.2-xml php8.2-bcmath php8.2-intl php8.2-readline

# Instalar y habilitar extensiones PECL
RUN pecl install swoole && \
    echo "extension=swoole.so" > /etc/php/8.2/mods-available/swoole.ini && \
    phpenmod swoole && \
    pecl install redis && \
    echo "extension=redis.so" > /etc/php/8.2/mods-available/redis.ini && \
    phpenmod redis

# Limpiar cache apt
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Instalar Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Crear y establecer directorio de trabajo
WORKDIR /var/www/html

# Copiar código fuente
COPY . .

# Asignar permisos adecuados a Laravel
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Copiar configuración PHP, Supervisor y crontab
COPY .deploy/config/php.ini /etc/php/8.2/fpm/php.ini
COPY .deploy/config/supervisor.conf /etc/supervisord.conf
COPY .deploy/config/crontab /etc/cron.d/laravel-schedule

# Hacer ejecutable el script de inicio
COPY .deploy/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Dar permisos y registrar el cron
RUN chmod 0644 /etc/cron.d/laravel-schedule && \
    crontab /etc/cron.d/laravel-schedule

# Exponer puerto usado por Octane
EXPOSE 9000

# Ejecutar entrypoint
CMD ["/entrypoint.sh"]
