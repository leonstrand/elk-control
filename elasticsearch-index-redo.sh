#!/bin/bash

# leon.strand@gmail.com


index="$1"
if [ -z "$index" ]; then
  echo $0: fatal: must provide index
  echo $0: usage: $0 \<index\>
  echo $0: example: $0 logstash-2016.11.06
  exit 1
fi

consul_agents='
10.153.13.35
10.153.13.36
'
consul_agent_port=8500


# check for consul agent, elasticsearch ip address and port, and successful connection to elasticsearch before proceeding
for consul_agent in $consul_agents; do
  echo
  if nc -w1 $consul_agent $consul_agent_port </dev/null 2>&1 >/dev/null; then
    break
  fi
done
if [ -z "$consul_agent" ]; then
  echo $0: fatal: could not find a live consul agent with:
  echo nc -w1 $consul_agent $consul_agent_port \</dev/null 2\&1 \/dev/null
  exit 1
fi
echo $0: info: consul agent: $consul_agent
host=$(curl -sS $consul_agent:$consul_agent_port/v1/health/service/elasticsearch-http?passing | jq -jr '.[0] | .Service | "\(.Address)"')
if [ -z "$host" ]; then
  echo $0: fatal: could not find a live elasticsearch node with:
  echo curl -sS $consul_agent:$consul_agent_port/v1/health/service/elasticsearch-http?passing \| jq -jr \''.[0] | .Service | "\(.Address)"'\'
  exit 1
fi
port=$(curl -sS $consul_agent:$consul_agent_port/v1/health/service/elasticsearch-http?passing | jq -jr '.[0] | .Service | "\(.Port)"')
if [ -z "$port" ]; then
  echo $0: fatal: could not find port associated with a live elasticsearch node with:
  echo curl -sS $consul_agent:$consul_agent_port/v1/health/service/elasticsearch-http?passing \| jq -jr \''.[0] | .Service | "\(.Port)"'\'
  exit 1
fi
if ! nc -w1 $host $port </dev/null; then
  echo $0: fatal: could not connect to elasticsearch at $host:$port
  exit 1
fi


post_to_new_index() {
echo $0: info: action 0 of 4: post to new index
data='
{
  "user" : "kimchy",
  "post_date" : "2009-11-15T14:12:12",
  "message" : "trying out Elasticsearch"
}
'
echo curl -sS http://$host:$port/twitter/tweet/1?wait_for_completion=true -XPUT -d \'"$data"\' \| jq
curl -sS http://$host:$port/twitter/tweet/1?wait_for_completion=true -XPUT -d "$data" | jq
}
echo
case "$index" in
  twitter)
    echo $0: info: twitter index specified, creating...
    post_to_new_index
  ;;
  *)
    echo $0: info: checking for index with:
    echo curl -v -XHEAD http://$host:$port/$index 2\>\&1 \| grep \''200 OK'\'
    if curl -v -XHEAD http://$host:$port/$index 2>&1 | grep '200 OK'; then
      echo $0: info: index $index found
    else
      echo $0: fatal: index $index not found
      exit 1
    fi
  ;;
esac


echo
echo $0: info: report 1 of 7: indices overview
echo curl -sS http://$host:$port/_cat/indices?v \| '(read -r; printf "%s\n" "$REPLY"; sort)'
curl -sS http://$host:$port/_cat/indices?v | (read -r; printf "%s\n" "$REPLY"; sort)
sleep 5

echo
echo $0: info: report 2 of 7: index settings
echo curl -sS http://$host:$port/$index/_settings \| jq
curl -sS http://$host:$port/$index/_settings | jq

echo
echo $0: info: action 1 of 4: make temporary index from old index
data='
{
  "source": {
    "index": "'$index'"
  },
  "dest": {
    "index": "'$index'-tmp"
  }
}
'
echo time curl -sS -XPOST http://$host:$port/_reindex?wait_for_completion=true -d \'$data\' \| jq
time curl -sS -XPOST http://$host:$port/_reindex?wait_for_completion=true -d "$data" | jq

echo
echo $0: info: report 3 of 7: indices overview
echo curl -sS http://$host:$port/_cat/indices?v \| '(read -r; printf "%s\n" "$REPLY"; sort)'
curl -sS http://$host:$port/_cat/indices?v | (read -r; printf "%s\n" "$REPLY"; sort)
sleep 5

echo
echo $0: info: action 2 of 4: delete old index
echo time curl -sS -XDELETE http://$host:$port/$index?wait_for_completion=true \| jq
time curl -sS -XDELETE http://$host:$port/$index?wait_for_completion=true | jq

echo
echo $0: info: report 4 of 7: indices overview
echo curl -sS http://$host:$port/_cat/indices?v \| '(read -r; printf "%s\n" "$REPLY"; sort)'
curl -sS http://$host:$port/_cat/indices?v | (read -r; printf "%s\n" "$REPLY"; sort)
sleep 5

echo
echo $0: info: action 3 of 4: make new index from temporary index
data='
{
  "source": {
    "index": "'$index'-tmp"
  },
  "dest": {
    "index": "'$index'"
  }
}
'
echo time curl -sS -XPOST http://$host:$port/_reindex?wait_for_completion=true -d \'$data\' \| jq
time curl -sS -XPOST http://$host:$port/_reindex?wait_for_completion=true -d "$data" | jq

echo
echo $0: info: report 5 of 7: indices overview
echo curl -sS http://$host:$port/_cat/indices?v \| '(read -r; printf "%s\n" "$REPLY"; sort)'
curl -sS http://$host:$port/_cat/indices?v | (read -r; printf "%s\n" "$REPLY"; sort)
sleep 5

echo
echo $0: info: action 4 of 4: delete temporary index
echo time curl -sS -XDELETE http://$host:$port/$index-tmp?wait_for_completion=true \| jq
time curl -sS -XDELETE http://$host:$port/$index-tmp?wait_for_completion=true | jq

echo
echo $0: info: report 6 of 7: index settings
echo curl -sS http://$host:$port/$index/_settings \| jq
curl -sS http://$host:$port/$index/_settings | jq

echo
echo $0: info: report 7 of 7: indices overview
echo curl -sS http://$host:$port/_cat/indices?v \| '(read -r; printf "%s\n" "$REPLY"; sort)'
curl -sS http://$host:$port/_cat/indices?v | (read -r; printf "%s\n" "$REPLY"; sort)
