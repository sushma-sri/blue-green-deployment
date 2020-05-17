FROM php:7.2-apache

COPY app/index.html /var/www/html/

WORKDIR /var/www/html/

EXPOSE 80
