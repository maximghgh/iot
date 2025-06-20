FROM php:8.2-fpm

# Системные пакеты
RUN apt-get update && apt-get install -y \
    git curl zip unzip nodejs npm \
    libzip-dev libpq-dev libonig-dev \
  && docker-php-ext-install pdo_pgsql mbstring zip

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www
COPY . .

RUN composer install --no-interaction --prefer-dist --optimize-autoloader \
 && npm install && npm run build \
 && php artisan config:cache

RUN chown -R www-data:www-data storage bootstrap/cache \
 && chmod -R 775 storage bootstrap/cache

EXPOSE 8080
CMD ["php", "-S", "0.0.0.0:8080", "-t", "public"]
