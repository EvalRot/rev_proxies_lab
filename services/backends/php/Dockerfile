FROM php:8.2-apache

# Enable useful Apache modules
RUN a2enmod rewrite headers && docker-php-ext-install -j"$(nproc)" opcache || true

WORKDIR /var/www/html
COPY src/ /var/www/html/
COPY apache.conf /etc/apache2/conf-enabled/override.conf

EXPOSE 80
