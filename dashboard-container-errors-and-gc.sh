#!/bin/bash

for h in $ELK_HOSTS; do
  echo
  echo $h
  ssh $ELK_USER@$h '
    for i in $(docker ps -aq); do
      lines="$(2>/dev/null docker logs $i | egrep '\''ERROR|gc'\'')"
      if [ -n "$lines" ]; then
        echo
        docker ps -af id=$i --format '\''{{.Names}}'\''
        echo "$lines"
        2>/dev/null docker exec $i date
      fi
    done | tee >(wc -l)
  '
done
