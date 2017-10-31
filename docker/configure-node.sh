set -m

### DEFAULTS
CLUSTER_USERNAME=${CLUSTER_USERNAME:='Administrator'}
CLUSTER_PASSWORD=${CLUSTER_PASSWORD:='password'}
CLUSTER_RAMSIZE=${CLUSTER_RAMSIZE:=400}
SERVICES=${SERVICES:='data,index,query,fts'}
BUCKET=${BUCKET:='social'}
BUCKET_RAMSIZE=${BUCKET_RAMSIZE:=100}

sleep 2
echo ' '
printf 'Waiting for Couchbase Server to start'
until $(curl --output /dev/null --silent --head --fail http://localhost:8091/pools); do
  printf .
  sleep 1
done

echo ' '
echo Couchbase Server has started
echo Starting configuration

echo Configuring Individual Node Settings
/opt/couchbase/bin/couchbase-cli node-init \
  --cluster localhost:8091 \
  --user=$CLUSTER_USERNAME \
  --password=$CLUSTER_PASSWORD \
  --node-init-data-path=${NODE_INIT_DATA_PATH:='/opt/couchbase/var/lib/couchbase/data'} \
  --node-init-index-path=${NODE_INIT_INDEX_PATH:='/opt/couchbase/var/lib/couchbase/indexes'} \
  --node-init-hostname=${NODE_INIT_HOSTNAME:='127.0.0.1'} \
> /dev/null

echo Configuring Cluster
CMD="/opt/couchbase/bin/couchbase-cli cluster-init"
CMD="$CMD --cluster localhost:8091"
CMD="$CMD --cluster-username=$CLUSTER_USERNAME"
CMD="$CMD --cluster-password=$CLUSTER_PASSWORD"
CMD="$CMD --cluster-ramsize=$CLUSTER_RAMSIZE"
# is the index service going to be running?
if [[ $SERVICES == *"index"* ]]; then
  CMD="$CMD --index-storage-setting=memopt"
  CMD="$CMD --cluster-index-ramsize=${CLUSTER_INDEX_RAMSIZE:=256}"
fi
# is the fts service going to be running?
if [[ $SERVICES == *"index"* ]]; then
  CMD="$CMD --cluster-fts-ramsize=${CLUSTER_FTS_RAMSIZE:=256}"
fi
CMD="$CMD --services=$SERVICES"
CMD="$CMD > /dev/null"
eval $CMD

echo Creating social bucket and loading data
/opt/couchbase/bin/cbimport json \
  -c couchbase://127.0.0.1 \
  -u $CLUSTER_USERNAME \
  -p $CLUSTER_PASSWORD \
  -b $BUCKET \
  -d /dataset.zip \
  -f sample \
  -t 4 \
> /dev/null

echo Creating social_user
couchbase-cli user-manage \
  --cluster localhost \
  --username Administrator \
  --password password \
  --set \
  --rbac-username social_user \
  --rbac-password secret \
  --rbac-name social_user \
  --roles bucket_admin[social] \
  --auth-domain local \
> /dev/null

echo The node has been successfully configured