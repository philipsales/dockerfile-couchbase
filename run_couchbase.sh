#!/bin/bash

set -x
set -m

/entrypoint.sh couchbase-server &

# Check if couchbase server is up
check_db() {
  curl --silent http://127.0.0.1:8091/pools > /dev/null
  echo $?
}

# Variable used in echo
i=1
# Echo with
numbered_echo() {
  echo "[$i] $@"
  i=`expr $i + 1`
}

# Parse JSON and get nodes from the cluster
read_nodes() {
  cmd="import sys,json;"
  cmd="${cmd} print(','.join([node['otpNode']"
  cmd="${cmd} for node in json.load(sys.stdin)['nodes']"
  cmd="${cmd} ]))"
  python -c "${cmd}"
}

# Wait until it's ready
until [[ $(check_db) = 0 ]]; do
  >&2 numbered_echo "Waiting for Couchbase Server to be available"
  sleep 1
done

echo "# Couchbase Server Online"
echo "# Starting setup process"

# Setup index and memory quota
curl -v -X POST http://127.0.0.1:8091/pools/default -d memoryQuota=$ALLOCMEMMB -d indexMemoryQuota=$ALLOCMEMMB

# Setup services
curl -v http://127.0.0.1:8091/node/controller/setupServices -d services=kv%2Cn1ql%2Cindex

# Setup credentials
curl -v http://127.0.0.1:8091/settings/web -d port=8091 -d username=$USERNAME -d password=$PASSWORD

# Setup Indexes 
#curl -i -u $USERNAME:$PASSWORD -X POST http://127.0.0.1:8091/settings/indexes -d 'storageMode=memory_optimized'
curl -i -u $USERNAME:$PASSWORD -X POST http://127.0.0.1:8091/settings/indexes -d "storageMode=forestdb"

# Load initial bucket
curl -v -u $USERNAME:$PASSWORD -X POST http://127.0.0.1:8091/pools/default/buckets -d name=$DB_NAME -d bucketType=couchbase -d ramQuotaMB=$ALLOCMEMMB -d authType=sasl

# Attach to couchbase entrypoint
numbered_echo "Attaching to couchbase-server entrypoint"
fg 1
