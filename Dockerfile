# 1) Базовый образ и системные зависимости
FROM php:8.2-fpm

RUN apt-get update && apt-get install -y \
    git curl zip unzip nodejs npm libzip-dev libpq-dev \
  && docker-php-ext-install pdo_pgsql mbstring zip

# 2) Установка Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

# 3) Копируем весь код приложения
COPY . .

# 4) Устанавливаем PHP-зависимости, копируем .env, генерируем ключ, собираем фронт, кешируем конфиг
RUN composer install --no-interaction --prefer-dist --optimize-autoloader \
 && cp .env.example .env \
 && php artisan key:generate --ansi \
 && npm install \
 && npm run build \
 && php artisan config:cache

# 5) Права на папки, используемые Laravel
RUN chown -R www-data:www-data storage bootstrap/cache \
 && chmod -R 775 storage bootstrap/cache

EXPOSE 8000

# 6) Запускаем PHP-сервер Railway как PID 1
CMD ["sh","-c","exec php -S 0.0.0.0:${PORT} -t public"]
