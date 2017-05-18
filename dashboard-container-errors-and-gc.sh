#!/bin/bash

for h in $ELK_HOSTS; do
  echo
  echo $h
  ssh $ELK_USER@$h '
    for i in $(docker ps -aq); do
      echo
      docker ps -af id=$i --format '\''{{.Names}}'\''
      2>/dev/null docker logs $i | egrep '\''ERROR|gc'\''
      2>/dev/null docker exec $i date
    done | tee >(wc -l)
  '
done
