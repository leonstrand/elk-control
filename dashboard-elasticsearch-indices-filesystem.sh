#!/bin/bash

while (( "$#" )); do
  echo $1
  ssh $1 du -s /elk/elasticsearch/elasticsearch-?/data/nodes/0/indices/*
  shift
  [ "$#" -gt 0 ] && echo
done
