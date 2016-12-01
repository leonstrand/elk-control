#!/bin/bash

# leon.strand@gmail.com


host='10.153.13.35'
port='19206'
#date=$1
#index='logstash-2016.11.06'
index='twitter'


post_to_new_index() {
echo
echo $0: info: action 0 of 4: post to new index
data='
{
  "user" : "kimchy",
  "post_date" : "2009-11-15T14:12:12",
  "message" : "trying out Elasticsearch"
}
'
}
post_to_new_index

echo curl -sS http://$host:$port/twitter/tweet/1?wait_for_completion=true -XPUT -d \'"$data"\' \| jq
curl -sS http://$host:$port/twitter/tweet/1?wait_for_completion=true -XPUT -d "$data" | jq

echo
echo $0: info: report 1 of 7: indices overview
echo curl -sS http://$host:$port/_cat/indices?v \| '(read -r; printf "%s\n" "$REPLY"; sort)'
curl -sS http://$host:$port/_cat/indices?v | (read -r; printf "%s\n" "$REPLY"; sort)
sleep 1

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
sleep 1

echo
echo $0: info: action 2 of 4: delete old index
echo time curl -sS -XDELETE http://$host:$port/$index?wait_for_completion=true \| jq
time curl -sS -XDELETE http://$host:$port/$index?wait_for_completion=true | jq

echo
echo $0: info: report 4 of 7: indices overview
echo curl -sS http://$host:$port/_cat/indices?v \| '(read -r; printf "%s\n" "$REPLY"; sort)'
curl -sS http://$host:$port/_cat/indices?v | (read -r; printf "%s\n" "$REPLY"; sort)
sleep 1

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
sleep 1

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
