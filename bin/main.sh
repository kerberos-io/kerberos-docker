#!/bin/bash

BASEDIR=$(cd `dirname $0` && pwd)

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
    read -p "Enter webinterface port: " webport
done

while [[ $streamport == '' ]] || ! [[ $streamport =~ $re ]] # While port is not set or not a number
do
    echo "Specify the port on which the livestreaming will be available."
    read -p "Enter livestreaming port: " streamport
done

out=$(docker run --name ${name} -p ${webport}:80 -p ${streamport}:8889 --mount type=bind,src=${BASEDIR}/environments/${environment},dst=/etc/opt/kerberosio/config -d kerberos/kerberos)
echo "Result: ${out}"
