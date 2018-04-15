
#!/bin/bash
set -e

# This is an example script that starts a single vtgate.

export VTROOT=/home/ubuntu
export VTDATAROOT=/home/ubuntu/vtdataroot

HOSTNAME="ec2-34-208-78-29.us-west-2.compute.amazonaws.com"
TOPOLOGY_FLAGS="-topo_implementation zk2 -topo_global_server_address ec2-34-208-78-29.us-west-2.compute.amazonaws.com:21811,ec2-34-213-57-41.us-west-2.compute.amazonaws.com:21811,ec2-34-208-152-137.us-west-2.compute.amazonaws.com:21811 -topo_global_root /vitess/global"
CELL="cell1"
GRPC_PORT=15991
WEB_PORT=15001
MYSQL_SERVER_PORT=15306
MYSQL_AUTH_PARAM=""

# This script stops vtgate.

set -e

pid=`cat $VTDATAROOT/tmp/vtgate.pid`
echo "Stopping vtgate..."
kill $pid
