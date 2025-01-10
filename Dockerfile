FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Bogota

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y bash git sudo openssh-client \
    libxml2-dev libonig-dev autoconf gcc g++ make \
    libfreetype6-dev libjpeg-turbo8-dev libpng-dev libzip-dev \
    curl unzip nano software-properties-common

RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

RUN add-apt-repository ppa:ondrej/php -y && \
    apt-get update && \
    apt-get install -y php8.2 php8.2-fpm php8.2-cli php8.2-common \
    php8.2-mysql php8.2-zip php8.2-gd php8.2-mbstring php8.2-curl php8.2-xml php8.2-bcmath \
    php8.2-intl php8.2-readline php8.2-pcov php8.2-dev

RUN pecl install swoole && \
    echo "extension=swoole.so" > /etc/php/8.2/mods-available/swoole.ini && \
    phpenmod swoole

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

WORKDIR /app

COPY . .

RUN composer install --no-interaction --optimize-autoloader --no-dev && \
    composer require laravel/octane --no-interaction && \
    php artisan octane:install --server=swoole && \
    npm install && npm run build && \
    chown -R www-data:www-data /app && \
    chmod -R 775 storage bootstrap/cache && \
    php artisan key:generate --force

CMD ["php", "artisan", "octane:start", "--server=swoole", "--host=0.0.0.0", "--port=9090", "--workers=4", "--task-workers=2"]

EXPOSE 9090