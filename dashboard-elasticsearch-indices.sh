#!/bin/bash

# leon.strand@medeanalytics.com


hosts=$ELK_HOSTS

for host in $hosts; do
  if nc -w1 $host 22 </dev/null 2>&1 >/dev/null; then
    ssh $host "PATH=\$PATH:/usr/sbin; ~/elk/dashboard-elasticsearch-indices.sh"
    break
  fi
done
