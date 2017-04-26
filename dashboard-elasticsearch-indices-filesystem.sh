#!/bin/bash

hosts=$ELK_HOSTS
for host in $hosts; do
  echo
  echo $host
  ssh $host du -s /elk/elasticsearch/elasticsearch-?/data/nodes/0/indices/*
done
