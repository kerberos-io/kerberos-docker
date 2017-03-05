FROM resin/armv7hf-debian-qemu

MAINTAINER "Cédric Verstraeten" <hello@cedric.ws>

RUN [ "cross-build-start" ]

#################################
# Surpress Upstart errors/warning

RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl

RUN apt-get update && apt-get upgrade
RUN apt-get -y install git supervisor curl subversion libcurl4-gnutls-dev cmake dh-autoreconf libav-tools autotools-dev autoconf automake gcc build-essential libtool make nasm zlib1g-dev tar libx264. nginx nodejs npm php5-fpm git php5-mysql php-apc php5-curl php5-gd php5-mcrypt php5-memcache php5-tidy php5-xsl pwgen

########################################
# fix ownership of sock file for php-fpm

RUN sed -i -e "s/;listen.mode = 0660/listen.mode = 0750/g" /etc/php5/fpm/pool.d/www.conf && \
find /etc/php5/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

########################################
# Force both nginx and PHP-FPM to run in the foreground
# This is a requirement for supervisor

RUN echo "daemon off;" >> /etc/nginx/nginx.conf
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf

############################
# Clone and build machinery

RUN git clone https://github.com/FFmpeg/FFmpeg && \
	cd FFmpeg && git checkout remotes/origin/release/2.8 && \
	./configure --enable-gpl --enable-libx264 && make && \
    make install && \
    cd .. && rm -rf FFmpeg

RUN [ "cross-build-end" ]
