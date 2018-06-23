#!/bin/bash
# Lucas Cardoso <mr.lucascardoso@gmail.com>"
# Script to manage the containers execution

build_haproxy(){
  echo 'Generating HAProxy image'
  docker build -t haproxy:1.6 .
}

main (){
  docker-compose down

  echo ''
  echo "Checking if HAProxy image already exists..."
  echo ''

  if ! [[ "$(docker images -q haproxy:1.6 2> /dev/null)" == "" ]]; then
    echo 'HAProxy image already exists'
    read -p 'Do you want to generate a new? (yes / no): ' generate_image
    if [[ $generate_image == 'yes' ]]; then
      echo 'Remove older images'
      docker rmi -f $(docker images -q haproxy)
      build_haproxy
    fi
  else
    build_haproxy
  fi

  ## Variables for images build.
  JOIN_RABBIT2_RABBIT1="rabbitmqctl stop_app; rabbitmqctl join_cluster rabbit@rabbitmq1; rabbitmqctl start_app"
  JOIN_RABBIT3_RABBIT1="rabbitmqctl stop_app; rabbitmqctl join_cluster rabbit@rabbitmq1; rabbitmqctl start_app"
  JOIN_RABBIT4_RABBIT1="rabbitmqctl stop_app; rabbitmqctl join_cluster rabbit@rabbitmq1; rabbitmqctl start_app"
  OPTIONAL_COMMAND="rabbitmqctl set_policy ha-all '' '{\"ha-mode\":\"all\", \"ha-sync-mode\":\"automatic\"}'"

  #Subindo os container's do rabbitmq
  echo ''
  echo "Starting container..."
  echo ''

  docker-compose up -d
  sleep 20
  docker exec -ti rabbitmq2 bash -c "$JOIN_RABBIT2_RABBIT1"
  docker exec -ti rabbitmq3 bash -c "$JOIN_RABBIT3_RABBIT1"
  docker exec -ti rabbitmq4 bash -c "$JOIN_RABBIT4_RABBIT1"
  docker exec -ti rabbitmq1 bash -c "$OPTIONAL_COMMAND"
}

main

