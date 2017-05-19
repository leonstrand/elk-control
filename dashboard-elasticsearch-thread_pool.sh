#!/bin/bash

#time for port in $(

work() {
  __host=$1
  #node_name                                        name                active queue rejected
  #sacelkpai102-elasticsearch-6                     bulk                     0     0        0
  ssh $ELK_USER@$__host '
    work() {
      __port=$1
      curl -sS $(hostname):$__port/_cat/thread_pool | awk '\''($4 > 0) || ($5 > 0) { print;}'\''
    }
    export -f work
    parallel work ::: $(netstat -lnt | grep :::192 | awk '\''{print $4}'\'' | tr -d :)
  '
}
export -f work
parallel work ::: $ELK_HOSTS
