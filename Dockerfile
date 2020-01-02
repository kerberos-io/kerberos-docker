FROM debian:buster

ARG APP_ENV=master
ENV APP_ENV ${APP_ENV}

MAINTAINER "Cédric Verstraeten" <hello@cedric.ws>

#################################
# Surpress Upstart errors/warning

RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl

#############################################
# Let the container know that there is no tty

ENV DEBIAN_FRONTEND noninteractive

#########################################
# Update base image
# Add sources for latest nginx and cmake
# Install software requirements

RUN apt-get update && apt-get install -y software-properties-common
RUN apt-get -y install git supervisor curl subversion libcurl4-gnutls-dev cmake dh-autoreconf autotools-dev autoconf automake gcc build-essential libtool make nasm zlib1g-dev tar libx264.
RUN apt install -y apt-transport-https lsb-release ca-certificates wget && \
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg && \
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list && \
apt -y update
RUN apt-get -y --force-yes install nginx nodejs npm php7.1-cli php7.1-gd php7.1-mcrypt php7.1-curl php7.1-mbstring php7.1-dom php7.1-zip php7.1-fpm pwgen

########################################
# fix ownership of sock file for php-fpm

RUN sed -i -e "s/;listen.mode = 0660/listen.mode = 0750/g" /etc/php/7.1/fpm/pool.d/www.conf && \
find /etc/php/7.1/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

########################################
# Force both nginx and PHP-FPM to run in the foreground
# This is a requirement for supervisor

RUN echo "daemon off;" >> /etc/nginx/nginx.conf
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.1/fpm/php-fpm.conf

############################
# Clone and build ffmpeg

RUN git clone https://github.com/FFmpeg/FFmpeg && \
	cd FFmpeg && git checkout remotes/origin/release/2.8 && \
	./configure --enable-gpl --enable-libx264 && make && \
    make install && \
    cd .. && rm -rf FFmpeg

############################
# Clone and build machinery

RUN	git clone https://github.com/kerberos-io/machinery /tmp/machinery && \
    cd /tmp/machinery && git checkout ${APP_ENV} && \
    mkdir build && cd build && \
    cmake .. && make && make check && make install && \
    rm -rf /tmp/machinery && \
    chown -Rf www-data.www-data /etc/opt/kerberosio && \
    chmod -Rf 777 /etc/opt/kerberosio/config

#####################
# Clone and build web

RUN curl -sL https://deb.nodesource.com/setup_9.x | bash - && apt-get install -y nodejs
RUN git clone https://github.com/kerberos-io/web /var/www/web && cd /var/www/web && git checkout ${APP_ENV} && \
chown -Rf www-data.www-data /var/www/web && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
cd /var/www/web && \
composer install --prefer-source && \
npm install -g bower && \
cd public && \
bower --allow-root install

RUN rm /var/www/web/public/capture && \
ln -s /etc/opt/kerberosio/capture/ /var/www/web/public/capture

# Fixes, because we are now combining the two docker images.
# Docker is aware of both web and machinery.
RUN sed -i -e "s/'insideDocker'/'insideDocker' => false,\/\//" /var/www/web/app/Http/Controllers/SystemController.php
# RUN sed -i -e "s/\$output \=/\$output \= '';\/\//" /var/www/web/app/Http/Controllers/SettingsController.php
RUN sed -i -e "s/service kerberosio status/supervisorctl status machinery \| grep \"RUNNING\"';\/\//" /var/www/web/app/Http/Repositories/System/OSSystem.php

###################
# nginx site conf

RUN rm -Rf /etc/nginx/conf.d/* && rm -Rf /etc/nginx/sites-available/default && mkdir -p /etc/nginx/ssl
ADD ./web.conf /etc/nginx/sites-available/default.conf
RUN ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf

##################################
# Fix PHP-FPM environment variables

RUN sed -i 's/"GPCS"/"EGPCS"/g' /etc/php/7.1/fpm/php.ini
RUN sed -i 's/"--daemonize/"--daemonize --allow-to-run-as-root/g' /etc/init.d/php7.1-fpm
RUN sed -i 's/www-data/root/g' /etc/php/7.1/fpm/pool.d/www.conf
RUN sed -i 's/www-data/root/g' /etc/nginx/nginx.conf

# Merged supervisord config of both web and machinery
ADD ./supervisord.conf /etc/supervisord.conf

# Merge the two run files.
ADD ./run.sh /runny.sh
RUN chmod 755 /runny.sh
RUN chmod +x /runny.sh
RUN sed -i -e 's/\r$//' /runny.sh

# Exposing web on port 80 and livestreaming on port 8889
EXPOSE 8889
EXPOSE 80

# Make capture and config directory visible
VOLUME ["/etc/opt/kerberosio/capture"]
VOLUME ["/etc/opt/kerberosio/config"]
VOLUME ["/etc/opt/kerberosio/logs"]

# Make web config directory visible
VOLUME ["/var/www/web/config"]

# Start runner script when booting container
CMD ["/bin/bash", "/runny.sh"]
