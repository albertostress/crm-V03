# Multi-stage Dockerfile for EspoCRM with custom configurations

# Stage 1: Build stage for frontend assets
FROM node:20-alpine AS frontend-builder

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY Gruntfile.js ./

# Install dependencies and build frontend
RUN npm ci --omit=dev
RUN npm run build

# Stage 2: Production image
FROM php:8.2-apache

# Install required PHP extensions and dependencies
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libldap2-dev \
    libxml2-dev \
    libzip-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libonig-dev \
    libpq-dev \
    libicu-dev \
    cron \
    supervisor \
    git \
    unzip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install \
        gd \
        pdo \
        pdo_mysql \
        pdo_pgsql \
        mysqli \
        ldap \
        zip \
        bcmath \
        mbstring \
    && docker-php-ext-enable opcache \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Enable Apache modules
RUN a2enmod rewrite expires headers

# Set recommended PHP.ini settings
RUN { \
    echo 'memory_limit=256M'; \
    echo 'max_execution_time=180'; \
    echo 'max_input_time=180'; \
    echo 'post_max_size=50M'; \
    echo 'upload_max_filesize=50M'; \
    echo 'max_file_uploads=20'; \
    echo 'date.timezone=UTC'; \
    } > /usr/local/etc/php/conf.d/espocrm.ini

# Configure OPcache for production
RUN { \
    echo 'opcache.enable=1'; \
    echo 'opcache.memory_consumption=256'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=10000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.fast_shutdown=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Set working directory
WORKDIR /var/www/html

# Copy ALL application files including customizations
COPY --chown=www-data:www-data . .

# Ensure custom directories are preserved
COPY --chown=www-data:www-data ./custom /var/www/html/custom
COPY --chown=www-data:www-data ./client/custom /var/www/html/client/custom
COPY --chown=www-data:www-data ./application/Espo/Modules /var/www/html/application/Espo/Modules

# Copy built frontend assets from build stage (only if they exist)
# This is optional since we're copying everything above
# COPY --from=frontend-builder --chown=www-data:www-data /app/client/lib ./client/lib
# COPY --from=frontend-builder --chown=www-data:www-data /app/client/css ./client/css

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chmod -R 775 /var/www/html/data \
    && chmod -R 775 /var/www/html/custom \
    && chmod -R 775 /var/www/html/client/custom

# Create volumes mount points
VOLUME ["/var/www/html/data", "/var/www/html/custom", "/var/www/html/client/custom"]

# Configure Apache
RUN { \
    echo '<VirtualHost *:80>'; \
    echo '    DocumentRoot /var/www/html/public'; \
    echo '    <Directory /var/www/html/public>'; \
    echo '        Options Indexes FollowSymLinks'; \
    echo '        AllowOverride All'; \
    echo '        Require all granted'; \
    echo '    </Directory>'; \
    echo '    ErrorLog ${APACHE_LOG_DIR}/error.log'; \
    echo '    CustomLog ${APACHE_LOG_DIR}/access.log combined'; \
    echo '</VirtualHost>'; \
    } > /etc/apache2/sites-available/000-default.conf

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s \
    CMD curl -f http://localhost/api/v1/App/health || exit 1

# Expose port
EXPOSE 80

# Add entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]