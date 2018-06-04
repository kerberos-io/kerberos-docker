function containerExists {
  name=$1
  if [ ! "$(docker ps -aq -f name=$name)" ]; then
    echo 0
  else
    echo 1
  fi
}
