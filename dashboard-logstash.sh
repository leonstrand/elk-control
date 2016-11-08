#!/bin/bash

# leon.strand@medeanalytics.com


hosts='
10.153.13.35
10.153.13.36
'

for host in $hosts; do
  if nc -w1 $host 22 </dev/null 2>&1 >/dev/null; then
    ssh $host "PATH=\$PATH:/usr/sbin; ~/elk/dashboard-logstash.sh"
    break
  fi
done