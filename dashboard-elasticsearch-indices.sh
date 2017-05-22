#!/bin/bash

# leon.strand@medeanalytics.com


hosts=$ELK_HOSTS
user=$ELK_USER

for host in $hosts; do
  ports=$(ssh $ELK_USER@$host docker ps -f name=elasticsearch --format='{{.Ports}}' | grep 9200)
  for port in $ports; do
    case $port in
      *9200*)
        # debug: port: 0.0.0.0:19201->9200/tcp,
        port=$(echo $port | sed 's/^.*:\(.*\)-.*$/\1/')
        echo curl -sS $host:$port/_cat/indices?v
        results="$(curl -sS $host:$port/_cat/indices?v)"
        if [ -n "$results" ]; then
          echo "$results" | head -1
          echo "$results" | tail -n +2 | sort -k3
          exit 0
        fi
      ;;
    esac
  done
done
