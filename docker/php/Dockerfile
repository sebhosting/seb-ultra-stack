FROM php:8.3-fpm

RUN apt-get update && apt-get install -y \ 
    libpng-dev libjpeg-dev libonig-dev libzip-dev libxml2-dev unzip curl git     && docker-php-ext-configure gd --with-jpeg     && docker-php-ext-install pdo pdo_mysql gd mbstring zip xml intl

# wp-cli
RUN curl -sO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar  && php wp-cli.phar --info >/dev/null 2>&1  && mv wp-cli.phar /usr/local/bin/wp && chmod +x /usr/local/bin/wp

WORKDIR /var/www/html
