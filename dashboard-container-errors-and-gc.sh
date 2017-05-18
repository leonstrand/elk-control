#!/bin/bash

for h in $ELK_HOSTS; do
  echo
  echo $h
  ssh $ELK_USER@$h '
    work() {
      __container=$1
      lines="$(2>/dev/null docker logs $__container | egrep '\''ERROR|gc'\'')"
      if [ -n "$lines" ]; then
        echo
        docker ps -af id=$__container --format '\''{{.Names}}'\''
        echo "$lines"
        2>/dev/null docker exec $__container date
      fi
    }
    export -f work
    parallel work ::: $(docker ps -aq)
  '
done | tee >(wc -l)
