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
echo elasticsearch cluster nodes
echo -e 'ip address\tport\troles'
master_node="$(curl -sS $address:$port/_cluster/state/master_node?pretty | jq -r '.master_node')"
elasticsearch_nodes=$(curl -sS $address:$port/_nodes/_all/http_address?pretty | grep -B1 '"name"' | egrep -v '"name"|^--' | awk '{print $1}' | tr -d \")
for elasticsearch_node in $elasticsearch_nodes; do
  node_ip="$(curl -sS $address:$port/_nodes/?pretty | jq -r '.nodes."'$elasticsearch_node'".settings.network.publish_host')"
  node_port="$(curl -sS $address:$port/_nodes/?pretty | jq -r '.nodes."'$elasticsearch_node'".settings.http.publish_port')"
  roles="$(curl -sS $address:$port/_nodes/?pretty | jq -r '.nodes."'$elasticsearch_node'".roles[]')"
  [ "$elasticsearch_node" != "$master_node" ] && roles="$(echo $roles | sed 's/\(master\)/\1-eligible/')"
  echo -e $node_ip'\t'$node_port'\t'$roles
done | sort -V
