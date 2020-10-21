#!/bin/bash
set -x

# from: https://reece.tech/posts/elasticsearch-unassigned-shard/
# script for fixing unallocated shards in ElasticSearch

ESHOST="$1"
FIRST_NODE=$(curl -s http://${ESHOST}:9200/_nodes?pretty |grep -A1 \"nodes\"|tail -n 1|cut -d\" -f2)
range="2"

for line in $(curl -s ${ESHOST}:9200/_cat/shards | fgrep UNASSIGNED); do
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
    "node" : '\"${1ST_NODE}\"',
    "accept_data_loss" : true
  }
}
]
}'
done

# This should only be run on installations with only one node
curl -s "${ESHOST}:9200/_cat/shards" | fgrep " r " |awk '{print $1}'|sort|uniq|while read i
do
   curl -XPUT "${ESHOST}:9200/$i/_settings?pretty" -H 'Content-Type: application/json' -d' { "number_of_replicas": 0 }'
done