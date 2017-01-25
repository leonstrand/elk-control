#!/bin/bash

# leon.strand@medeanalytics.com


hosts=$ELK_HOSTS
user=$ELK_USER

for host in $hosts; do
  if nc -w1 $host 22 </dev/null 2>&1 >/dev/null; then
    ssh $user@$host "PATH=\$PATH:/usr/sbin; ~$user/elk/dashboard-elasticsearch-indices.sh"
    break
  fi
done
