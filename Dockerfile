FROM php:8.2-fpm

# 1) Системные зависимости
RUN apt-get update && apt-get install -y \
    git curl zip unzip nodejs npm \
    libzip-dev libpq-dev libonig-dev \
  && docker-php-ext-install pdo_pgsql mbstring zip

# 2) Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www
COPY . .

# 3) deps + фронт + кеш
RUN composer install --no-interaction --prefer-dist --optimize-autoloader \
 && cp .env.example .env \
 && php artisan key:generate --ansi \
 && npm install \
 && npm run build \
 && php artisan config:cache

RUN chown -R www-data:www-data storage bootstrap/cache \
 && chmod -R 775 storage bootstrap/cache

EXPOSE 8000
CMD ["php", "-d", "variables_order=EGPCS", "-S", "0.0.0.0:${PORT}", "-t", "public"]

