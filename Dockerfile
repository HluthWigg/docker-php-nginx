ARG ALPINE_VERSION=3.17
FROM alpine:${ALPINE_VERSION}
LABEL Maintainer="HluthWigg"
LABEL Description="Lightweight Paheko 1.2.6 container with Nginx 1.22 & PHP 8.1 based on Alpine Linux."
# Setup document root
WORKDIR /var/www/

# Change the version here
ENV GARRADIN_VERSION 1.2.6

# Install packages and remove default server definition
RUN apk add --no-cache \
  curl \
  nginx \
  php81 \
  php81-ctype \
  php81-curl \
  php81-dom \
  php81-fpm \
  php81-gd \
  php81-intl \
  php81-mbstring \
  #php81-mysqli \
  php81-opcache \
  php81-openssl \
  php81-phar \
  php81-session \
  php81-xml \
  php81-xmlreader \
  php81-sqlite3 \
  #php81-pdo_sqlite \
  php81-fileinfo \
  php81-json \
  php81-openssl \
  php81-zlib \
  php81-zip \
  gettext \
  supervisor

# Downloading and installing Garradin
RUN curl -L -O https://fossil.kd2.org/garradin/uv/paheko-$GARRADIN_VERSION.tar.gz # download
RUN tar xzvf paheko-$GARRADIN_VERSION.tar.gz # extract
RUN mv paheko-$GARRADIN_VERSION /var/www/garradin # root of the website
RUN rm -r paheko-$GARRADIN_VERSION.tar.gz # cleaning

# Download and install plugins
RUN cd /var/www/garradin/data/plugins && \
curl -L -O https://fossil.kd2.org/garradin-plugins/uv/ouvertures.tar.gz ; \
curl -L -O https://fossil.kd2.org/garradin-plugins/uv/stock_velos.tar.gz ; \
curl -L -O https://fossil.kd2.org/garradin-plugins/uv/reservations.tar.gz ; \
curl -L -O https://fossil.kd2.org/garradin-plugins/uv/webstats.tar.gz ; \
curl -L -O https://fossil.kd2.org/garradin-plugins/uv/dompdf.tar.gz ; \ 
curl -L -O https://fossil.kd2.org/garradin-plugins/uv/git_documents.tar.gz ; \
curl -L -O https://fossil.kd2.org/garradin-plugins/uv/taima.tar.gz ; \
curl -L -O https://fossil.kd2.org/garradin-plugins/uv/caisse.tar.gz ;
#RUN curl -L -O https://fossil.kd2.org/garradin-plugins/uv/helloasso.tar.gz
#RUN curl -L -O https://fossil.kd2.org/garradin-plugins/uv/dompdf.tar.gz
#RUN curl -L -O https://fossil.kd2.org/garradin-plugins/uv/taima.tar.gz
#RUN mv helloasso.tar.gz /var/www/garradin/data/plugins/
#RUN mv *.tar.gz /var/www/garradin/data/plugins/


# Configure nginx - http
COPY config/nginx.conf /etc/nginx/nginx.conf
# Configure nginx - default server
COPY config/conf.d /etc/nginx/conf.d/

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php81/php-fpm.d/www.conf
COPY config/php.ini /etc/php81/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /var/www/garradin /run /var/lib/nginx /var/log/nginx

# Switch to use a non-root user from here on
USER nobody

# Add application
# COPY --chown=nobody src/ /var/www/html/

# Expose the port nginx is reachable on
EXPOSE 80

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
