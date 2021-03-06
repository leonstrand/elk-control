#!/bin/bash

# leonstrand@gmail.com


hosts=$ELK_HOSTS
user='elk'
directory=~$user/elk
elasticsearch_nodes_per_host=10
logstash_directory_logs=$LOGSTASH_DIRECTORY_LOGS
logstash_container_name_prefix=$LOGSTASH_CONTAINER_NAME_PREFIX
consul_logstash_service_name=$logstash_container_name_prefix
loop_threshold=300
loop_threshold_logstash=$loop_threshold


stop_and_remove_all_containers() {
  work() {
    __host=$1
      containers="$(ssh $user@$__host docker ps -aq)"
      if [ -n "$containers" ]; then
        echo
        echo $0: $__host containers detected\; stopping and removing...
        echo ssh $user@$__host \''docker stop $(docker ps -aq) && docker rm $(docker ps -aq)'\'
        ssh $user@$__host 'docker stop $(docker ps -aq) && docker rm $(docker ps -aq)'
      fi
      dangling_images="$(ssh $user@$__host docker images -qf dangling=true)"
      if [ -n "$dangling_images" ]; then
        echo
        echo $0: $__host dangling images detected\; removing...
        echo ssh $user@$__host \''docker rmi $(docker images -f dangling=true -q)'\'
        ssh $user@$__host 'docker rmi $(docker images -f dangling=true -q)'
      fi
      dangling_volumes="$(ssh $user@$__host docker volume ls -qf dangling=true)"
      if [ -n "$dangling_volumes" ]; then
        echo
        echo $0: $__host dangling volumes detected\; removing...
        echo ssh $user@$__host \''docker volume rm $(docker volume ls -qf dangling=true)'\'
        ssh $user@$__host 'docker volume rm $(docker volume ls -qf dangling=true)'
      fi
      echo
      echo ssh root@$__host rm -frv /elk/elasticsearch/*
      ssh root@$__host rm -frv /elk/elasticsearch/*
      echo
      echo ssh root@$__host rm -frv /elk/logstash/*
      ssh root@$__host rm -frv /elk/logstash/*
  }
  for host in $hosts; do
    work $host &
  done
  wait
  for host in $hosts; do
    echo
    echo
    echo ssh $user@$host docker ps -a
    ssh $user@$host docker ps -a
    echo
    echo ssh $user@$host docker images -f dangling=true
    ssh $user@$host docker images -f dangling=true
    echo
    echo ssh $user@$host docker volume ls -f dangling=true
    ssh $user@$host docker volume ls -f dangling=true
    echo
    echo ssh $user@$host ls -alh /elk/elasticsearch
    ssh $user@$host ls -alh /elk/elasticsearch
  done
}

start_consul_agents() {
  consul_bootstrap=''
  for host in $hosts; do
    echo
    echo
    echo -n $(date '+%Y-%m-%d %H:%M:%S.%N')\ 
    echo $0: host: $host
    if [ -z "$consul_bootstrap" ]; then
      ssh $user@$host "PATH=\$PATH:/usr/sbin; cd $directory && time ./spinup-consul.sh b"
      consul_bootstrap=$host
    else
      echo -n $(date '+%Y-%m-%d %H:%M:%S.%N')\ 
      echo $0: waiting for response from bootstrap consul agent at $consul_bootstrap:8500
      echo curl --connect-timeout 1 $consul_bootstrap:8500
      until curl --connect-timeout 1 $consul_bootstrap:8500 1>/dev/null 2>&1; do
        echo -n .
        sleep 0.1
      done
      echo
      curl --connect-timeout 1 $consul_bootstrap:8500
      echo
      ssh $user@$host "PATH=\$PATH:/usr/sbin; cd $directory && time ./spinup-consul.sh $consul_bootstrap"
    fi
    echo
    echo
    echo -n $(date '+%Y-%m-%d %H:%M:%S.%N')\ 
    echo $0: waiting for consul agent to finish starting
    echo ssh $user@$host docker logs consul-1 \| grep \""\[INFO\] agent: Synced service 'consul'"\"
    until ssh $user@$host docker logs consul-1 | grep "\[INFO\] agent: Synced service 'consul'"; do
      echo -n .
      sleep 0.1
    done
    echo
    ssh $user@$host docker logs consul-1 | grep "\[INFO\] agent: Synced service 'consul'"
  done
}

start_elasticsearch_cluster() {
  nodes_up=0
  for i in $(seq $elasticsearch_nodes_per_host); do
    for host in $hosts; do
      echo
      echo
      echo -n $(date '+%Y-%m-%d %H:%M:%S.%N')\ 
      echo $0: spinning up elasticsearch node on $host
      ssh $user@$host "PATH=\$PATH:/usr/sbin; cd $directory && time ./spinup-elasticsearch.sh"
      nodes_up=$(expr $nodes_up + 1)
      echo
      echo
      echo -n $(date '+%Y-%m-%d %H:%M:%S.%N')\ 
      echo $0: waiting for elasticsearch node to start
      echo ssh $user@$host docker logs \$\(ssh $user@$host docker ps -lqf label=elasticsearch\) \| grep started
      until ssh $user@$host docker logs $(ssh $user@$host docker ps -lqf label=elasticsearch) | grep started; do
        echo -n .
        sleep 0.1
      done
      echo
      ssh $user@$host docker logs $(ssh $user@$host docker ps -lqf label=elasticsearch) | grep started
      echo -n $(date '+%Y-%m-%d %H:%M:%S.%N')\ 
      echo $0: waiting for all elasticsearch nodes to pass
      until [ $(curl -sS $consul_bootstrap:8500/v1/health/service/elasticsearch-transport?passing | jq -jr '.[] | .Service | .Address + ":" + "\(.Port)" + ","' | sed 's/,$//' | tr , \\n | wc -w) -eq $nodes_up ]; do 
        echo -n .
        sleep 0.1
      done
      echo
      echo curl -sS $consul_bootstrap:8500/v1/health/service/elasticsearch-transport?passing \| jq -jr \''.[] | .Service | .Address + ":" + "\(.Port)" + ","'\' \| sed \''s/,$//'\' \| tr , \\\\n
      curl -sS $consul_bootstrap:8500/v1/health/service/elasticsearch-transport?passing | jq -jr '.[] | .Service | .Address + ":" + "\(.Port)" + ","' | sed 's/,$//' | tr , \\n
      echo
    done
  done
}

start_kibana_front_ends() {
  for host in $hosts; do
    echo
    echo
    echo -n $(date '+%Y-%m-%d %H:%M:%S.%N')\ 
    echo $0: spinning up kibana front end on $host
    ssh $user@$host "PATH=\$PATH:/usr/sbin; cd $directory && time ./spinup-kibana.sh"
    echo
    echo
    echo -n $(date '+%Y-%m-%d %H:%M:%S.%N')\ 
    echo $0: waiting for kibana to finish starting
    echo ssh $user@$host docker logs kibana-1 \| grep \''Server running'\'
    until ssh $user@$host docker logs kibana-1 | grep 'Server running'; do
      echo -n .
      sleep 0.1
    done
    echo
  done
}

start_logstash_instances() {
  echo
  echo
  host=$(echo $hosts | awk '{print $1}')
  servers=$(ssh $user@$host "find $logstash_directory_logs -maxdepth 1 -mindepth 1 -type d -exec basename {} \;" | sort)
  container_sequence=0
  rest() { shift; echo $*; }
  echo -n $(date '+%Y-%m-%d %H:%M:%S.%N')\ 
  echo $0: spinning up logstash instances
  while [ -n "$servers" ]; do
    container_sequence=$(expr $container_sequence + 1)
    container_name=$logstash_container_name_prefix-$container_sequence
    for host in $hosts; do
      server=$(echo $servers | awk '{print $1}')
      if [ -n "$server" ]; then
        echo -n $(date '+%Y-%m-%d %H:%M:%S.%N')\ 
        echo $0: debug: command: ssh $user@$host \""PATH=\$PATH:/usr/sbin; cd $directory && time ./spinup-logstash-parallel.sh $container_name $server"\"
        ssh $user@$host "PATH=\$PATH:/usr/sbin; cd $directory && time ./spinup-logstash-parallel.sh $container_name $server"
        servers=$(rest $servers)
      fi
    done
  done
  host=$(echo $hosts | awk '{print $1}')
  echo
  echo
  logstash_instances_total=$(ssh $user@$host find /pai-logs -type d -mindepth 1 -maxdepth 1 | wc -l)
  echo -n $(date '+%Y-%m-%d %H:%M:%S.%N')\ 
  echo $0: logstash_instances_total: $logstash_instances_total
  logstash_instances=0
  echo -n $(date '+%Y-%m-%d %H:%M:%S.%N')\ 
  echo $0: waiting for actual live logstash instance count to equal expected
  loop_count=0
  until [ $logstash_instances -eq $logstash_instances_total ]; do
    echo -en $0: logstash instances: expected: $logstash_instances_total, actual:\\t
    logstash_instances_actual="$(curl -sS http://$consul_bootstrap:8500/v1/health/service/$consul_logstash_service_name?passing | jq '.[] | .Service | .ID' | wc -w)"
    echo -en $logstash_instances_actual\\t
    loop_count=$(expr $loop_count + 1)
    echo -e loop count: $loop_count,\\tloop threshold logstash: $loop_threshold_logstash
    if [ $loop_count -ge $loop_threshold_logstash ]; then
      echo -n $(date '+%Y-%m-%d %H:%M:%S.%N')\ 
      echo $0: fatal: loop count $loop_count exceeded threshold $loop_threshold_logstash, exiting...
      break
    else
      sleep 1
      logstash_instances=$(curl -sS http://$host:8500/v1/health/service/$consul_logstash_service_name?passing | jq '.[] | .Service | .ID' | wc -w)
    fi
  done
  echo -en $0: logstash instances: expected: $logstash_instances_total, actual:\\t
  curl -sS http://$consul_bootstrap:8500/v1/health/service/$consul_logstash_service_name?passing | jq '.[] | .Service | .ID' | wc -w
}

stop_and_remove_all_containers
start_consul_agents
start_elasticsearch_cluster
start_kibana_front_ends
start_logstash_instances
echo
echo
echo -n $(date '+%Y-%m-%d %H:%M:%S.%N')\ 
echo $0: elk cluster startup complete
echo
echo
echo
