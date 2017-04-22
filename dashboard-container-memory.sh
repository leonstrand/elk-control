#!/bin/bash

# leon.strand@medeanalytics.com


host=$1
user=elk
echo $0: host: $host
echo
if nc -w1 $host 22 </dev/null 2>&1 >/dev/null; then
  ssh $user@$host '~/elk/dashboard-container-memory.sh'
fi
