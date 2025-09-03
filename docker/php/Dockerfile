FROM php:8.4-fpm

# Dependências do sistema
RUN apt-get update && apt-get install -y \
    git unzip curl libpq-dev libzip-dev libssl-dev zlib1g-dev \
    libicu-dev libxml2-dev libcurl4-openssl-dev libpng-dev \
    libjpeg-dev libfreetype6-dev supervisor \
    && rm -rf /var/lib/apt/lists/*

# Extensões PHP
RUN docker-php-ext-install pdo pdo_pgsql pdo_mysql zip gd intl curl opcache

# Extensões PECL
RUN pecl install redis xdebug swoole \
    && docker-php-ext-enable redis swoole \
    && echo "zend_extension=xdebug.so" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.start_with_request=no" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.client_port=9003" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Supervisor e scripts
COPY ./supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY ./start-app.sh /usr/local/bin/start-app.sh
RUN chmod +x /usr/local/bin/start-app.sh

WORKDIR /var/www/html
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]