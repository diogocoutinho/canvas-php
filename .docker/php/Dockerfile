FROM php:8.4-fpm-alpine

# Install system dependencies (including build deps required by Swoole)
RUN apk add --no-cache \
    postgresql-dev \
    libzip-dev \
    zlib-dev \
    openssl-dev \
    zip \
    unzip \
    git \
    linux-headers \
    build-base \
    autoconf

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_pgsql zip pcntl

# Install Swoole (let pecl pick a compatible release for the PHP version)
RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS openssl-dev zlib-dev brotli-dev \
    && pecl channel-update pecl.php.net \
    && pecl install -f swoole \
    && docker-php-ext-enable swoole \
    && printf "extension=swoole.so\n" > "$PHP_INI_DIR/conf.d/docker-php-ext-swoole.ini" \
    && rm -rf /tmp/pear /tmp/* \
    && apk del .build-deps

# Configure PHP
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copy start script and make it executable
COPY start-app.sh /usr/local/bin/start-app
RUN chmod +x /usr/local/bin/start-app

CMD ["/usr/local/bin/start-app"]
