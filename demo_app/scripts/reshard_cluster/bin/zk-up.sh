#!/bin/bash

ZK_CONFIG="1@ec2-34-208-78-29.us-west-2.compute.amazonaws.com:28881:38881:21811,2@ec2-34-213-57-41.us-west-2.compute.amazonaws.com:28881:38881:21811,3@ec2-34-208-152-137.us-west-2.compute.amazonaws.com:28881:38881:21811"
ZK_SERVER="ec2-34-208-78-29.us-west-2.compute.amazonaws.com:21811,ec2-34-213-57-41.us-west-2.compute.amazonaws.com:21811,ec2-34-208-152-137.us-west-2.compute.amazonaws.com:21811"
TOPOLOGY_FLAGS="-topo_implementation zk2 -topo_global_server_address ec2-34-208-78-29.us-west-2.compute.amazonaws.com:21811,ec2-34-213-57-41.us-west-2.compute.amazonaws.com:21811,ec2-34-208-152-137.us-west-2.compute.amazonaws.com:21811 -topo_global_root /vitess/global"
CELL="cell1"


echo "Starting zk servers..."

/home/ubuntu/vitess-deployment/bin/run_script_on_host.sh ec2-34-208-78-29.us-west-2.compute.amazonaws.com /home/ubuntu/vitess-deployment/bin/ec2-34-208-78-29.us-west-2.compute.amazonaws.com/zk-up-instance-001.sh


/home/ubuntu/vitess-deployment/bin/run_script_on_host.sh ec2-34-213-57-41.us-west-2.compute.amazonaws.com /home/ubuntu/vitess-deployment/bin/ec2-34-213-57-41.us-west-2.compute.amazonaws.com/zk-up-instance-002.sh


/home/ubuntu/vitess-deployment/bin/run_script_on_host.sh ec2-34-208-152-137.us-west-2.compute.amazonaws.com /home/ubuntu/vitess-deployment/bin/ec2-34-208-152-137.us-west-2.compute.amazonaws.com/zk-up-instance-003.sh


# Create /vitess/global and /vitess/CELLNAME paths if they do not exist.
/home/ubuntu/bin/zk -server ${ZK_SERVER} touch -p /vitess/global
/home/ubuntu/bin/zk -server ${ZK_SERVER} touch -p /vitess/${CELL}

# Initialize cell.
/home/ubuntu/bin/vtctl ${TOPOLOGY_FLAGS} AddCellInfo -root /vitess/${CELL} -server_address ${ZK_SERVER} ${CELL}
