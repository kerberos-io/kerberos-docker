#!/bin/bash

BASEDIR=$(cd `dirname $0` && pwd)
source "$BASEDIR/src/check_docker.sh"

function create {
    name=$1
    environment=$2
    webport=$3
    streamport=$4

    # Validation of parameters
    while [[ $name == '' ]] || [ "$(containerExists kerberos-$name)" -eq "1" ] # While containername is valid or empty...
    do
        echo "Specify a name for the container (this needs to be unique)."
        echo "Make sure a container with the same name doesn't exists."
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

    output=$(docker run --name kerberos-${name} -p ${webport}:80 -p ${streamport}:8889 --mount type=bind,src=${BASEDIR}/environments/${environment},dst=/etc/opt/kerberosio/config -d kerberos/kerberos 2>/dev/null)
    echo $output
    if [[ $output == '' ]]
    then
      echo "Hmm, something went wrong while creating the container."
    else
      echo "Container succesfully created!"
      echo "Adding container command to autostart.sh"
      command >> "$BASEDIR/autostart/autostart.sh"
    fi
}

function cleanup {
    echo "Stop all running Kerberos.io containers"
    docker stop $(docker ps -aq --filter="name=kerberos")
    echo "Remove all containers"
    docker rm $(docker ps -aq --filter="name=kerberos")
}

function start {
    echo "Running all docker containers from autostart.sh"
}

# Sanity checks for docker binary.
# Check if docker is installed.
#TODO
# Check if docker is running.
#TODO

# Fetch input parameters
command=$1

case "$command" in
  "cleanup")
      cleanup
      ;;
  "create")
      create $2 $3 $4 $5
      ;;
  "start")
      start
      ;;
esac
