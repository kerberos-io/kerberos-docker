#!/bin/bash

autoremoval() {
  while true; do
    sleep 60
    if [[ $(df -h /etc/opt/kerberosio/capture | tail -1 | awk -F' ' '{ print $5/1 }' | tr ['%'] ["0"]) -gt 90 ]];
    then
      echo "Cleaning disk"
      find /etc/opt/kerberosio/capture/ -type f | sort | head -n 100 | xargs rm;
    fi;
  done
}

copyConfigFiles() {
  # Check if the config dir is empty, this can happen due to mapping
  # an empty filesystem to the volume.
  TEMPLATE_DIR=/etc/opt/kerberosio/template
  CONFIG_DIR=/etc/opt/kerberosio/config
  if [ "$(ls -A $CONFIG_DIR)" ]; then
      echo "Config files are available."
  else
      echo "Config files are missing, copying from template."
      cp /etc/opt/kerberosio/template/* /etc/opt/kerberosio/config/
      chmod -R 777 /etc/opt/kerberosio/config
  fi

  # Do the same for the web config
  TEMPLATE_DIR=/var/www/web/template
  CONFIG_DIR=/var/www/web/config
  if [ "$(ls -A $CONFIG_DIR)" ]; then
      echo "Config files are available."
  else
      echo "Config files are missing, copying from template."
      cp /var/www/web/template/* /var/www/web/config/
      chmod -R 777 /var/www/web/config
  fi
}

# replace SESSION_COOKIE_NAME
random=$((1+RANDOM%10000))
sed -i -e "s/kerberosio_session/kerberosio_session_$random/" /var/www/web/.env

autoremoval &
copyConfigFiles &

# Add environments vars to php
env | grep "KERBEROSIO_" | sed "s/\(.*\)=\(.*\)/env[\1]='\2'/" >> /etc/php7/php-fpm.d/www.conf

/usr/bin/supervisord -n -c /etc/supervisord.conf
