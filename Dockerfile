FROM php:8.2-fpm

# Установка зависимостей
RUN apt-get update && apt-get install -y \
    build-essential \
    libpng-dev \
    libjpeg-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    git \
    curl \
    nodejs \
    npm \
    libpq-dev \
    libzip-dev \
    && docker-php-ext-install pdo pdo_mysql pdo_pgsql mbstring exif pcntl bcmath gd zip

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

# Копируем проект
COPY . .

# Установка зависимостей Laravel и сборка фронта
RUN composer install --no-interaction --prefer-dist --optimize-autoloader \
    && npm install && npm run build \
    && php artisan config:cache \
    && php artisan route:cache \
    && php artisan view:cache \
    && mkdir -p storage/app/public \FROM php:8.2-fpm

# (ваши установки расширений, composer, npm и т.д.)

WORKDIR /var/www
COPY . .

RUN composer install --no-interaction --prefer-dist --optimize-autoloader \
    && npm install && npm run build \
    && php artisan config:cache

# Даем права на storage
RUN chown -R www-data:www-data storage bootstrap/cache

EXPOSE 8000
CMD ["sh","-c","exec php -S 0.0.0.0:${PORT} -t public"]
