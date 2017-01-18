#!/bin/bash

# leonstrand@gmail.com


hosts='
sacelk101
sacelk102
'

stop_and_remove_all_containers() {
  work() {
    __host=$1
      containers="$(ssh $__host docker ps -aq)"
      if [ -n "$containers" ]; then
        echo
        echo $0: $__host containers detected\; stopping and removing...
        echo ssh $__host \''docker stop $(docker ps -aq) && docker rm $(docker ps -aq)'\'
        ssh $__host 'docker stop $(docker ps -aq) && docker rm $(docker ps -aq)'
      fi
      dangling_images="$(ssh $__host docker images -qf dangling=true)"
      if [ -n "$dangling_images" ]; then
        echo
        echo $0: $__host dangling images detected\; removing...
        echo ssh $__host \''docker rmi $(docker images -f dangling=true -q)'\'
        ssh $__host 'docker rmi $(docker images -f dangling=true -q)'
      fi
      dangling_volumes="$(ssh $__host docker volume ls -qf dangling=true)"
      if [ -n "$dangling_volumes" ]; then
        echo
        echo $0: $__host dangling volumes detected\; removing...
        echo ssh $__host \''docker volume rm $(docker volume ls -qf dangling=true)'\'
        ssh $__host 'docker volume rm $(docker volume ls -qf dangling=true)'
      fi
  }
  for host in $hosts; do
    work $host &
  done
  wait
  for host in $hosts; do
    echo
    echo
    echo ssh $host docker ps -a
    ssh $host docker ps -a
    echo
    echo ssh $host docker images -f dangling=true
    ssh $host docker images -f dangling=true
    echo
    echo ssh $host docker volume ls -f dangling=true
    ssh $host docker volume ls -f dangling=true
  done
}

stop_and_remove_all_containers
echo
echo
echo -n $(date '+%Y-%m-%d %H:%M:%S.%N')\ 
echo $0: elk cluster stop and remove complete
echo
echo
