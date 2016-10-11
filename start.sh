#!/bin/bash

# leonstrand@gmail.com


#10.153.13.36
hosts='
10.153.13.35
'
directory=~/elk
elasticsearch_nodes_per_host=5


stop_and_remove_all_containers() {
  for host in $hosts; do
    echo
    echo
    echo $0: host: $host
    ssh $host '. ~/bashrc/docker && dsr all'
  done
}

start_consul_agents() {
  consul_bootstrap=''
  for host in $hosts; do
    echo
    echo
    echo $0: host: $host
    if [ -z "$consul_bootstrap" ]; then
      ssh $host "PATH=\$PATH:/usr/sbin; cd $directory && time ./spinup-consul.sh b"
      consul_bootstrap=$host
    else
      echo $0: waiting for response from bootstrap consul agent at $consul_bootstrap:8500
      echo curl --connect-timeout 1 $consul_bootstrap:8500
      until curl --connect-timeout 1 $consul_bootstrap:8500 1>/dev/null 2>&1; do
        sleep 0.1
      done
      curl --connect-timeout 1 $consul_bootstrap:8500
      echo
      ssh $host "PATH=\$PATH:/usr/sbin; cd $directory && time ./spinup-consul.sh $consul_bootstrap"
    fi
    echo
    echo
    echo $0: waiting for consul agent to finish starting
    echo ssh $host docker logs consul-1 \| grep \""\[INFO\] agent: Synced service 'consul'"\"
    until ssh $host docker logs consul-1 | grep "\[INFO\] agent: Synced service 'consul'"; do
      sleep 0.1
    done
  done
}

start_elasticsearch_cluster() {
  nodes_up=0
  for i in $(seq $elasticsearch_nodes_per_host); do
    for host in $hosts; do
      echo
      echo
      echo $0: spinning up elasticsearch node on $host
      ssh $host "PATH=\$PATH:/usr/sbin; cd $directory && time ./spinup-elasticsearch.sh"
      nodes_up=$(expr $nodes_up + 1)
      echo
      echo
      echo $0: waiting for elasticsearch node to start
      until ssh $host docker logs $(ssh $host docker ps -lqf label=elasticsearch) | grep started; do
        echo ssh $host docker logs \$\(ssh $host docker ps -lqf label=elasticsearch\) \| grep started
        sleep 1
      done
      echo $0: waiting for all elasticsearch nodes to pass
      until [ $(curl -sS $consul_bootstrap:8500/v1/health/service/elasticsearch-transport?passing | jq -jr '.[] | .Service | .Address + ":" + "\(.Port)" + ","' | sed 's/,$//' | tr , \\n | wc -w) -eq $nodes_up ]; do 
        echo curl -sS $consul_bootstrap:8500/v1/health/service/elasticsearch-transport?passing \| jq -jr \''.[] | .Service | .Address + ":" + "\(.Port)" + ","'\' \| sed \''s/,$//'\' \| tr , \\\\n
        curl -sS $consul_bootstrap:8500/v1/health/service/elasticsearch-transport?passing | jq -jr '.[] | .Service | .Address + ":" + "\(.Port)" + ","' | sed 's/,$//' | tr , \\n
        echo
        sleep 1
      done
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
    echo $0: spinning up kibana front end on $host
    ssh $host "PATH=\$PATH:/usr/sbin; cd $directory && time ./spinup-kibana.sh"
    echo
    echo
    echo $0: waiting for kibana to finish starting
    echo ssh $host docker logs kibana-1 \| grep \''Server running'\'
    until ssh $host docker logs kibana-1 | grep 'Server running'; do
      echo -n .
      sleep 0.1
    done
    echo
  done
}

start_logstash_instances() {
  #consul_bootstrap='10.153.13.35'
  echo
  echo
  logstash_instances_total=$(ssh $consul_bootstrap find /pai-logs -type d -mindepth 1 -maxdepth 1 | wc -l)
  echo $0: logstash_instances_total: $logstash_instances_total
  echo $0: log directories on $consul_bootstrap
  ssh $consul_bootstrap find /pai-logs -type d -mindepth 1 -maxdepth 1
  logstash_instances=0
  until [ $logstash_instances -eq $logstash_instances_total ]; do
    for host in $hosts; do
      echo
      echo
      echo $0: spinning up logstash instance on $host
      ssh $host "PATH=\$PATH:/usr/sbin; cd $directory && time ./spinup-logstash.sh"
      logstash_instances=$(expr $logstash_instances + 1)
      #echo $0: logstash_instances: $logstash_instances
      echo
      echo
      echo $0: live logstash instances:
      curl -sS http://$consul_bootstrap:8500/v1/health/service/logstash?passing | jq '.[] | .Service | .ID' | tr -d \" | sort
      echo $0: expected live logstash instance count: $logstash_instances
      echo -n $0: actual live logstash instance count:\ 
      curl -sS http://$consul_bootstrap:8500/v1/health/service/logstash?passing | jq '.[] | .Service | .ID' | wc -w
      echo $0: waiting for actual to equal expected
      echo $0: checking actual with:
      echo curl -sS http://$consul_bootstrap:8500/v1/health/service/logstash?passing \| jq \''.[] | .Service | .ID'\' \| wc -w
      until [ $(curl -sS http://$consul_bootstrap:8500/v1/health/service/logstash?passing | jq '.[] | .Service | .ID' | wc -w) -eq $logstash_instances ]; do
        sleep 1
      done
      echo -n $0: actual live logstash instance count:\ 
      curl -sS http://$consul_bootstrap:8500/v1/health/service/logstash?passing | jq '.[] | .Service | .ID' | wc -w
    done
  done
}

stop_and_remove_all_containers
start_consul_agents
start_elasticsearch_cluster
start_kibana_front_ends
start_logstash_instances
