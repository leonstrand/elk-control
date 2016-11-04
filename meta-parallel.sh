#!/bin/bash

# leon.strand@medeanalytics.com


loop=0
sleep_seconds=600

while :; do
  time ./start-parallel.sh 2>&1 | tee ./start-parallel.sh.log
  loop=$(expr $loop + 1)
  echo
  echo
  echo =============================================================================================
  echo $0: info: loop $loop complete
  echo =============================================================================================
  echo
  echo
  echo $0: info: seconds remaining before next loop:
  for i in $(seq 0 $(expr $sleep_seconds - 1)); do
    echo -en $(expr $sleep_seconds - $i)
    sleep 1
    echo -ne "\r\033[2K"
  done
done
