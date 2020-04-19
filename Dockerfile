FROM debian:stretch AS builder
MAINTAINER "Cédric Verstraeten" <hello@cedric.ws>

ARG APP_ENV=master
ENV APP_ENV ${APP_ENV}
ARG PHP_VERSION=7.1
ARG FFMPEG_VERSION=3.1

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

RUN apt-get update && apt-get install -y apt-transport-https wget lsb-release && \
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg && \
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list && \
apt -y update && \
apt -y install software-properties-common libssl-dev git supervisor curl \
subversion libcurl4-gnutls-dev cmake dh-autoreconf autotools-dev autoconf automake gcc g++ \
build-essential libtool make nasm zlib1g-dev tar apt-transport-https \
ca-certificates wget nginx php${PHP_VERSION}-cli php${PHP_VERSION}-gd php${PHP_VERSION}-mcrypt php${PHP_VERSION}-curl \
php${PHP_VERSION}-mbstring php${PHP_VERSION}-dom php${PHP_VERSION}-zip php${PHP_VERSION}-fpm pwgen && \
curl -sL https://deb.nodesource.com/setup_9.x | bash - && apt-get install -y nodejs npm

RUN wget http://www.nasm.us/pub/nasm/releasebuilds/2.13.01/nasm-2.13.01.tar.bz2 && \
tar xjvf nasm-2.13.01.tar.bz2  && \
cd nasm-2.13.01  && \
./autogen.sh  && \
./configure  && \
make  && \
make install

RUN apt-get install nasm

############################
# Clone and build x264

RUN git clone https://code.videolan.org/videolan/x264 /tmp/x264 && \
	cd /tmp/x264 && \
	git checkout df79067c && \
	./configure --prefix=/usr --enable-shared --enable-static --enable-pic && make && make install

############################
# Clone and build ffmpeg

# Get latest userland tools and build. Clean up unused stuff at the end
RUN cd \
    && git clone --depth 1 https://github.com/raspberrypi/userland.git \
    && cd userland \
		&& sed -i 's/sudo//g' ./buildme \
    && ./buildme \
    && rm -rf ../userland
RUN apt-get install libomxil-bellagio-dev -y
RUN apt-get install -y pkg-config && git clone https://github.com/FFmpeg/FFmpeg && \
	cd FFmpeg && git checkout remotes/origin/release/${FFMPEG_VERSION} && \
	./configure --enable-nonfree --enable-libx264 --enable-gpl && make && \
    make install && \
    cd .. && rm -rf FFmpeg

############################
# Clone and build machinery

RUN git clone https://github.com/kerberos-io/machinery /tmp/machinery && \
    cd /tmp/machinery && git checkout ${APP_ENV} && \
    mkdir build && cd build && \
    cmake .. && make && make check && make install && \
    rm -rf /tmp/machinery && \
    chown -Rf www-data.www-data /etc/opt/kerberosio && \
    chmod -Rf 777 /etc/opt/kerberosio/config

#####################
# Clone and build web

RUN git clone https://github.com/kerberos-io/web /var/www/web && cd /var/www/web && git checkout a17c2db770cce5c9f2aa4c13d76367647a9dba4d && \
chown -Rf www-data.www-data /var/www/web && curl -sSk https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
cd /var/www/web && \
composer install --prefer-source && \
npm config set unsafe-perm true && \
npm config set registry http://registry.npmjs.org/ && \
npm config set strict-ssl=false && \
npm install -g bower && \
cd public && \
sed -i 's/https/http/g' .bowerrc && \
bower --allow-root install

RUN rm /var/www/web/public/capture && \
ln -s /etc/opt/kerberosio/capture/ /var/www/web/public/capture

# Fixes, because we are now combining the two docker images.
# Docker is aware of both web and machinery.

RUN sed -i -e "s/'insideDocker'/'insideDocker' => false,\/\//" /var/www/web/app/Http/Controllers/SystemController.php
RUN sed -i -e "s/service kerberosio status/supervisorctl status machinery \| grep \"RUNNING\"';\/\//" /var/www/web/app/Http/Repositories/System/OSSystem.php

# Let's create a /dist folder containing just the files necessary for runtime.
# Later, it will be copied as the / (root) of the output image.

WORKDIR /dist
RUN mkdir -p ./etc/opt && cp -r /etc/opt/kerberosio ./etc/opt/
RUN mkdir -p ./usr/bin && cp /usr/bin/kerberosio ./usr/bin/
RUN mkdir -p ./var/www && cp -r /var/www/web ./var/www/
RUN mkdir -p ./usr/lib && cp -r /opt/vc/lib/* ./usr/lib/
RUN cp /usr/local/bin/ffmpeg /usr/bin/ffmpeg

# Optional: in case your application uses dynamic linking (often the case with CGO),
# this will collect dependent libraries so they're later copied to the final image
# NOTE: make sure you honor the license terms of the libraries you copy and distribute
RUN ldd /usr/bin/kerberosio | tr -s '[:blank:]' '\n' | grep '^/' | \
    xargs -I % sh -c 'mkdir -p $(dirname ./%); cp % ./%;'

FROM alpine:latest

#################################
# Copy files from previous images

COPY --chown=0:0 --from=builder /dist /

RUN apk update && apk add ca-certificates && \
    apk add --no-cache tzdata && rm -rf /var/cache/apk/*

####################################
# ADD supervisor and STARTUP script

RUN apk add supervisor && mkdir -p /var/log/supervisor/
ADD ./supervisord.conf /etc/supervisord.conf
ADD ./run.sh /run.sh
RUN chmod 755 /run.sh && chmod +x /run.sh

######################
# INSTALL Nginx

RUN apk add nginx && mkdir -p /run/nginx
COPY web.conf /etc/nginx/conf.d/default.conf
RUN chmod -R 777 /var/www/web/bootstrap/cache/ && \
		chmod -R 777 /var/www/web/storage && \
		chmod 777 /var/www/web/config/kerberos.php && \
		chmod -R 777 /etc/opt/kerberosio/config

######################
# INSTALL PHP

ARG PHP_VERSION=7

RUN apk add php${PHP_VERSION}-cli php${PHP_VERSION}-gd php${PHP_VERSION}-mcrypt php${PHP_VERSION}-curl \
php${PHP_VERSION}-mbstring php${PHP_VERSION}-dom php${PHP_VERSION}-simplexml php${PHP_VERSION}-zip php${PHP_VERSION}-tokenizer php${PHP_VERSION}-json php${PHP_VERSION}-session php${PHP_VERSION}-xml php${PHP_VERSION}-openssl php${PHP_VERSION}-fpm
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php7/php-fpm.conf

############################
# COPY template folder

# Copy the config template to filesystem
ADD ./config /etc/opt/kerberosio/template

########################################################
# Exposing web on port 80 and livestreaming on port 8889

EXPOSE 8889
EXPOSE 80

############################
# Volumes

VOLUME ["/etc/opt/kerberosio/capture"]
VOLUME ["/etc/opt/kerberosio/config"]
VOLUME ["/etc/opt/kerberosio/logs"]
VOLUME ["/var/www/web/config"]

CMD ["sh", "/run.sh"]
