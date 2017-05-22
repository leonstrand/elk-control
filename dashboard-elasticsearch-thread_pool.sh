#!/bin/bash


work() {
  __host=$1
  ssh $ELK_USER@$__host '
    work() {
      __port=$1
      curl -sS $(hostname):$__port/_cat/thread_pool/?h=node_name,po,name,t,a,ma,q,r | awk '\''($5 > 1) || ($7 > 0) || ($8 > 0) { print}'\''
    }
    export -f work
    parallel work ::: $(netstat -lnt | grep :::192 | awk '\''{print $4}'\'' | tr -d :)
  '
}
export -f work
parallel work ::: $ELK_HOSTS | sort -V | uniq
