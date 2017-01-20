#!/bin/bash

# leon.strand@medeanalytics.com


consul_agents=$CONSUL_AGENTS
consul_port=$CONSUL_PORT

# select first responsive consul agent
for consul_agent in $consul_agents; do
  if nc -w1 $consul_agent $consul_port </dev/null 2>&1 >/dev/null; then
    #echo made connection
    break
  fi
done

# get elasticsearch ip address and port
address=$(curl -sS $consul_agent:$consul_port/v1/health/service/elasticsearch-http?passing | jq -jr '.[0] | .Service | "\(.Address)"')
if [ -z "$address" ]; then
  echo $0: fatal: could not find a live elasticsearch node with:
  echo curl -sS $consul_agent:$consul_port/v1/health/service/elasticsearch-http?passing \| jq -jr \''.[0] | .Service | "\(.Address)"'\'
  exit 1
fi
port=$(curl -sS $consul_agent:$consul_port/v1/health/service/elasticsearch-http?passing | jq -jr '.[0] | .Service | "\(.Port)"')
if [ -z "$port" ]; then
  echo $0: fatal: could not find port associated with a live elasticsearch node with:
  echo curl -sS $consul_agent:$consul_port/v1/health/service/elasticsearch-http?passing \| jq -jr \''.[0] | .Service | "\(.Port)"'\'
  exit 1
fi

# check for elasticsearch successful connection
if ! nc -w1 $address $port </dev/null; then
  echo $0: fatal: could not connect to elasticsearch at $address:$port
  exit 1
fi


# output cluster health
command="curl -sS $address:$port/_cluster/health | jq -C ."
echo $command
eval $command


# output cluster summary, state, etc
command="curl -sS $address:$port/_cluster/state/version,master_node?pretty | jq -C ."
echo $command
eval $command


# output elasticsearch nodes and roles
echo
#echo $0: elasticsearch cluster nodes
echo elasticsearch cluster nodes
echo -e 'ip address\tport\trole'
master_node=$(curl -sS $address:$port/_cluster/state/master_node?pretty | grep master_node | awk '{print $NF}' | tr -d \")
elasticsearch_nodes=$(curl -sS $address:$port/_nodes/_all/http_address?pretty | grep -B1 '"name"' | egrep -v '"name"|^--' | awk '{print $1}' | tr -d \")
for elasticsearch_node in $elasticsearch_nodes; do
  http_address=$(curl -sS $address:$port/_nodes/$elasticsearch_node/http_address?pretty | grep '"http_address"' | awk '{print $NF}' | tr -d '",')
  node_ip=$(echo $http_address | cut -d: -f1)
  node_port=$(echo $http_address | cut -d: -f2)
  role=
  if [ "$master_node" == "$elasticsearch_node" ]; then
    role='master, data'
  else
    if curl -sS $address:$port/_nodes/$elasticsearch_node/http_address?pretty | grep -A2 '"attributes"' | grep -v attributes | grep -q '"data" : "false"'; then
      if curl -sS $address:$port/_nodes/$elasticsearch_node/http_address?pretty | grep -A2 '"attributes"' | grep -v attributes | grep -q '"master" : "false"'; then
        role='loadbalancer'
      fi
    else
      role='data'
    fi
  fi
  echo -e $node_ip'\t'$node_port'\t'$role
done | sort -V
