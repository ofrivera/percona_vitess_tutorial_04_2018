#!/bin/bash
# This script runs interactive vtworker.
set -e
echo vtworker.sh $@
read -p "Hit Enter to run the above command ..."
TOPOLOGY_FLAGS="-topo_implementation zk2 -topo_global_server_address ec2-34-208-78-29.us-west-2.compute.amazonaws.com:21811,ec2-34-213-57-41.us-west-2.compute.amazonaws.com:21811,ec2-34-208-152-137.us-west-2.compute.amazonaws.com:21811 -topo_global_root /vitess/global"
exec $VTROOT/bin/vtworker   $TOPOLOGY_FLAGS   -cell cell1   -log_dir $VTDATAROOT/tmp   -alsologtostderr   -use_v3_resharding_mode   "$@"
