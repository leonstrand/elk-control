#!/bin/bash

# leon.strand@medeanalytics.com


loop=0
sleep=600

while :; do
  time ./start.sh 2>&1 | tee ./start.sh.log
  loop=$(expr $loop + 1)
  echo
  echo
  echo =============================================================================================
  echo $0: info: loop $loop complete
  echo $0: info: sleeping for $sleep seconds...
  echo =============================================================================================
  echo
  echo
  sleep $sleep
done
