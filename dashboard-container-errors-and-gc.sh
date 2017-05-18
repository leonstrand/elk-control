#!/bin/bash

for h in $ELK_HOSTS; do
  echo
  echo $h
  ssh $ELK_USER@$h '
    for i in $(docker ps -aq); do
    docker logs $i | egrep "ERROR|gc"
  done'
done
