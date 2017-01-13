#!/bin/bash

# leonstrand@gmail.com


hosts=$@
directory=~/elk

start_consul() {
  echo
  echo
  echo $0: info: starting consul
  for host in $hosts; do
    echo
    echo ssh $host time docker start $\\\(docker ps -aqf name=consul\\\)
    ssh $host time docker start $\(docker ps -aqf name=consul\)
  done
  echo
  echo $0: info: sleep 60
  sleep 60
}
start_elasticsearch() {
  echo
  echo
  echo $0: info: starting elasticsearch
  for host in $hosts; do
    for container in $(ssh $host docker ps -aqf label=elasticsearch); do
      echo
      echo ssh $host time docker start $container
      ssh $host time docker start $container
      echo
      echo $0: info: sleep 120
      sleep 120
    done
  done

}
start_kibana() {
  echo
  echo
  echo $0: info: starting kibana loadbalancer
  for host in $hosts; do
    for container in $(ssh $host docker ps -af name=kibana | grep elasticsearch | awk '{print $1}'); do
      echo
      echo ssh $host time docker start $container
      ssh $host time docker start $container
      echo
      echo $0: info: sleep 120
      sleep 120
    done
  done
  echo
  echo $0: info: starting kibana
  for host in $hosts; do
    for container in $(ssh $host docker ps -af name=kibana | egrep -v 'CONTAINER|elasticsearch' | awk '{print $1}'); do
      echo
      echo ssh $host time docker start $container
      ssh $host time docker start $container
      echo
      echo $0: info: sleep 60
      sleep 60
    done
  done
}
restart_logstash() {
  echo
  echo
  echo $0: info: stopping logstash
  for host in $hosts; do
    for container in 'logstash-3'; do
      echo ssh $host time docker stop $container
      ssh $host time docker stop $container
    done
  done
  echo
  echo
  echo $0: info: starting logstash
  for host in $hosts; do
    #echo ssh $host time docker start $\\\(docker ps -aqf name=logstash -f status=exited\\\)
    #echo ssh $host 'time docker start $(docker ps -f name=logstash -f status=exited | grep -v CONTAINER | awk {print $NF})'
    #for container in 'logstash-3'; do
    for container in $(ssh $host docker ps -f name=logstash -f status=exited | grep -v CONTAINER | awk '{print $NF}'); do
      #ssh $host time docker start $\(docker ps -aqf name=logstash\)
      #echo ssh $host \''cd ~/elk && time ./restart-logstash.sh logstash-1'\'
      echo
      echo ssh $host \''cd ~/elk && time ./restart-logstash.sh '\'$container
      ssh $host 'cd ~/elk && time ./restart-logstash.sh '$container
    done
  done
}

start_consul
start_elasticsearch
start_kibana
restart_logstash
