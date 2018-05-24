FROM resin/rpi-raspbian

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

RUN apt-get update && \
apt-get install -y software-properties-common
RUN apt-get -y install git supervisor curl subversion libcurl4-gnutls-dev cmake dh-autoreconf libav-tools autotools-dev autoconf automake gcc build-essential libtool make nasm zlib1g-dev tar libx264.
RUN apt-get install apt-transport-https lsb-release ca-certificates wget
RUN apt-get -y --force-yes install nginx nodejs npm php7.0-cli php7.0-gd php7.0-mcrypt php7.0-curl php7.0-mbstring php7.0-dom php7.0-zip php7.0-fpm pwgen

########################################
# fix ownership of sock file for php-fpm

RUN sed -i -e "s/;listen.mode = 0660/listen.mode = 0750/g" /etc/php/7.0/fpm/pool.d/www.conf && \
find /etc/php/7.0/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

########################################
# Force both nginx and PHP-FPM to run in the foreground
# This is a requirement for supervisor

RUN echo "daemon off;" >> /etc/nginx/nginx.conf
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.0/fpm/php-fpm.conf

############################
# Clone and build machinery

RUN apt-get install libomxil-bellagio-dev -y
RUN git clone https://github.com/FFmpeg/FFmpeg && \
	cd FFmpeg && git checkout remotes/origin/release/3.1 && \
	./configure --arch=armel --target-os=linux --enable-gpl --enable-omx --enable-omx-rpi --enable-nonfree --enable-libx264 && make && \
    make install && \
    cd .. && rm -rf FFmpeg
