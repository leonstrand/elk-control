#!/bin/bash

#time for port in $(

work() {
  __host=$1
  echo
  echo $__host
  ssh $ELK_USER@$__host '
    work() {
      __port=$1
      curl -sS $(hostname):$__port/_nodes/_local/hot_threads
    }
    export -f work
    parallel work ::: $(netstat -lnt | grep :::192 | awk '\''{print $4}'\'' | tr -d :)
  '
}
export -f work
parallel work ::: $ELK_HOSTS
