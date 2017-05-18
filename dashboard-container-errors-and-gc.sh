#!/bin/bash

work() {
  __host=$1
  echo
  echo $__host
  ssh $ELK_USER@$__host '
    work() {
      __container=$1
      lines="$(2>/dev/null docker logs $__container | egrep '\''ERROR|gc'\'')"
      if [ -n "$lines" ]; then
        echo
        docker ps -af id=$__container --format '\''{{.Names}}'\''
        echo "$lines" | tee >(wc -l)
        2>/dev/null docker exec $__container date
      fi
    }
    export -f work
    parallel work ::: $(docker ps -aq)
  '
}
export -f work
parallel work ::: $ELK_HOSTS | tee >(wc -l)
