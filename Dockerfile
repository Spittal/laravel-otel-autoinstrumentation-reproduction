FROM php:fpm-alpine

# Add PHP Extensions
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions \
  # Laravel extensions that aren't pre-installed
  bcmath \
  mbstring \
  # Otel extensions that aren't pre-installed (left out GRPC because it's huge)
  protobuf \
  open-telemetry/opentelemetry-php-instrumentation@main

# Add Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer

# Add NGINX
RUN apk add --no-cache nginx
# Copy over nginx configuration, which is slightly modified from the laravel recommended https://laravel.com/docs/10.x/deployment#nginx
COPY default.conf /etc/nginx/http.d/default.conf

# Copy over the laravel code (note, the only thing I changed was adding min-stability to dev in composer.json)
COPY --chown=www-data:www-data ./ /var/www/

WORKDIR /var/www

RUN composer require open-telemetry/opentelemetry-auto-laravel

# Start php-fpm and nginx
CMD ["/bin/sh", "-c", "php-fpm -D && nginx -g 'daemon off;'"]
