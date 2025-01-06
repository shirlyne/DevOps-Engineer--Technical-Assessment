#10. Write a Dockerfile to containerize a Laravel application.

# Base image with PHP 8.2 and Apache
FROM php:8.2-apache AS base

# Install PHP extensions and dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev unzip libzip-dev \
    libjpeg-dev libpng-dev \
    libfreetype6-dev libwebp-dev \
    zlib1g-dev && \
    docker-php-ext-install mysqli pdo pdo_mysql pdo_pgsql && \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp && \
    docker-php-ext-install -j$(nproc) gd zip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Enable Apache modules
RUN a2enmod rewrite ssl

# Configure Apache to listen on port 8089
RUN sed -i.bak 's/Listen 80/Listen 8089/' /etc/apache2/ports.conf && \
    sed -i.bak 's/<VirtualHost \*:80>/<VirtualHost \*:8089>/' /etc/apache2/sites-available/000-default.conf

# Update Document Root for Laravel project
RUN sed -i 's|/var/www/html|/var/www/html/corporate/public|' /etc/apache2/sites-available/000-default.conf

# Install Composer (locked to a stable version)
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html/corporate

# Copy application code
COPY . .

# Set appropriate permissions for Laravel storage and cache
RUN chown -R www-data:www-data storage bootstrap/cache && \
    chmod -R 775 storage bootstrap/cache

# Install PHP dependencies for production
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist

# Configure PHP settings
RUN echo "memory_limit=512M" > /usr/local/etc/php/conf.d/php-memory-limit.ini && \
    echo "max_execution_time=300" > /usr/local/etc/php/conf.d/php-max-execution-time.ini

# Expose the port used by Apache
EXPOSE 8089

# Run Apache in the foreground
CMD ["apache2-foreground"]
