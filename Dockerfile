FROM php:8.2-fpm

RUN apt-get update && apt-get install -y \
    git curl zip unzip nodejs npm \
    libzip-dev libpq-dev libonig-dev \
 && docker-php-ext-install pdo_pgsql mbstring zip

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www
COPY . .

# Устанавливаем зависимости и собираем фронт
RUN composer install --no-interaction --prefer-dist --optimize-autoloader \
 && npm install \
 && npm run build \
 && php artisan config:cache

# Права
RUN chown -R www-data:www-data storage bootstrap/cache \
 && chmod -R 775 storage bootstrap/cache

# Railway слушает именно 8080 у Docker-образов
EXPOSE 8080

# PID 1 = php-server, без лишнего shell
CMD ["php", "-S", "0.0.0.0:8080", "-t", "public"]
