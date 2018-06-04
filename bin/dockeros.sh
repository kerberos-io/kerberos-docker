#!/bin/bash

BASEDIR=$(cd `dirname $0` && pwd)
source "$BASEDIR/src/docker.sh"

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
  "showall")
      showall
      ;;
esac
