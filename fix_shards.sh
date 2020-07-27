#!/bin/bash

# from: https://reece.tech/posts/elasticsearch-unassigned-shard/
# script for fixing unallocated shards in ElasticSearch

ESHOST="192.168.1.200"
range="2"
IFS=$'\n'

for line in $(curl -s '${ESHOST}:9200/_cat/shards' | fgrep UNASSIGNED); do
  INDEX=$(echo $line | (awk '{print $1}'))
  SHARD=$(echo $line | (awk '{print $2}'))
  number=$RANDOM
  let "number %= ${range}"
  curl -XPOST http://${ESHOST}:9200/_cluster/reroute? -d '{
  "commands" : [ {
  "allocate_empty_primary" :
  {
    "index" : '\"${INDEX}\"',
    "shard" : '\"${SHARD}\"',
    "node" : "8-z76-oUQkOUq66ICP4I1g",
    "accept_data_loss" : true
  }
}
]
}'
done
