#!/bin/bash

BASEDIR=$(cd `dirname $0` && pwd)
my_dir="$(dirname "$0")"
"$my_dir/src/check_docker.sh"

while [[ $name == '' ]] # While containername is valid or empty...
do
    echo "Specify a name for the container (this needs to be unique)."
    read -p "Enter container name: " name
done

while [[ $environment == '' ]] || [[ ! -d "$BASEDIR/environments/$environment" ]] # While environment is valid or empty...
do
    echo "Specify the name of the environment you which to load; subdir in the /environments folder."
    read -p "Enter environment: " environment
done

re='^[0-9]+$'
while [[ $webport == '' ]] || ! [[ $webport =~ $re ]] # While port is not set or not a number
do
    echo "Specify the port on which the webinterface will be available."
    read -p "Enter webinterface  port: " webport
done

while [[ $streamport == '' ]] || ! [[ $streamport =~ $re ]] # While port is not set or not a number
do
    echo "Specify the port on which the livestreaming will be available."
    read -p "Enter livestreaming port: " streamport
done

command="docker run --name ${name} -p ${webport}:80 -p ${streamport}:8889 --restart unless-stopped --mount type=bind,src=${BASEDIR}/environments/${environment},dst=/etc/opt/kerberosio/config -d kerberos/kerberos 2>/dev/null"
output=$(command)

if [[ $output == '' ]]
then
  echo "Hmm, something went wrong while creating the container."
else
  echo "Container succesfully created!"
  echo "Adding container command to autostart.sh"
  command >> "$my_dir/autostart/autostart.sh"
fi
