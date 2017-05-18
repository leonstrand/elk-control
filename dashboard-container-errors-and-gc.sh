#!/bin/bash

work_summary() {
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
        line_count=$(echo "$lines" | wc -l)
        if [ $line_count -le 10 ]; then
          echo "$lines"
        else
          echo "$lines" | head -5
          echo ...
          echo "$lines" | tail -5
        fi
        2>/dev/null docker exec $__container date
        echo container line count: $line_count
      fi
    }
    export -f work
    parallel work ::: $(docker ps -aq)
  '
}
work_total() {
  __host=$1
  ssh $ELK_USER@$__host '
    work() {
      __container=$1
      2>/dev/null docker logs $__container | egrep '\''ERROR|gc'\''
    }
    export -f work
    parallel work ::: $(docker ps -aq)
  '
}
export -f work_summary work_total
parallel work_summary ::: $ELK_HOSTS
echo
echo -n total line count:\ 
parallel work_total ::: $ELK_HOSTS | wc -l
