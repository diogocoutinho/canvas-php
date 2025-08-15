FROM php:8.2-fpm

# Dependências do sistema
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    curl \
    libpq-dev \
    libzip-dev \
    libssl-dev \
    zlib1g-dev \
    pkg-config \
    supervisor \
    && docker-php-ext-install pdo pdo_pgsql zip \
    && rm -rf /var/lib/apt/lists/*

# Extensões PECL: redis, xdebug, swoole
RUN pecl install redis xdebug swoole \
    && docker-php-ext-enable redis xdebug swoole

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Xdebug config
RUN echo "zend_extension=xdebug.so" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.client_port=9003" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# Supervisor + scripts
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start-app.sh /usr/local/bin/start-app.sh
COPY setup-framework.sh /usr/local/bin/setup-framework.sh
COPY inside-container-init.sh /usr/local/bin/inside-container-init.sh
COPY minio-bucket.sh /usr/local/bin/minio-bucket.sh
RUN chmod +x /usr/local/bin/*.sh

WORKDIR /var/www/html
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]