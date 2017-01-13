#!/bin/bash

# leon.strand@medeanalytics.com


hosts='
sacelk101
sacelk102
'

for host in $hosts; do
  echo
  echo $0: host: $host
  if nc -w1 $host 22 </dev/null 2>&1 >/dev/null; then
    ssh $host "PATH=\$PATH:/usr/sbin; ~/elk/dashboard-host-memory-disk.sh" | grep -v '^$'
  fi
done
