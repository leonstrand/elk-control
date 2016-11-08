#!/bin/bash

# leon.strand@medeanalytics.com


host=$1
echo $0: host: $host
if nc -w1 $host 22 </dev/null 2>&1 >/dev/null; then
  ssh $host "PATH=\$PATH:/usr/sbin; ~/elk/dashboard-container-memory.sh"
fi
