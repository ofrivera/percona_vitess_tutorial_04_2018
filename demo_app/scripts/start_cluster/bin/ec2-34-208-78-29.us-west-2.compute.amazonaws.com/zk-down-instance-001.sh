#!/bin/bash
# Generated file, edit at your own risk.

export VTROOT=/home/ubuntu
export VTDATAROOT=/home/ubuntu/vtdataroot
ZK_ID=1
ZK_DIR=zk_001
ZK_CONFIG=1@ec2-34-208-78-29.us-west-2.compute.amazonaws.com:28881:38881:21811,2@ec2-34-213-57-41.us-west-2.compute.amazonaws.com:28881:38881:21811,3@ec2-34-208-152-137.us-west-2.compute.amazonaws.com:28881:38881:21811


# Variables used below would be assigned values above this line

mkdir -p $VTDATAROOT/tmp

action='shutdown'

$VTROOT/bin/zkctl -zk.myid $ZK_ID -zk.cfg $ZK_CONFIG -log_dir $VTDATAROOT/tmp $action \
		  > $VTDATAROOT/tmp/zkctl_$ZK_ID.out 2>&1 &

if ! wait $!; then
    echo "ZK server number $ZK_ID failed to stop. See log:"
    echo "    $VTDATAROOT/tmp/zkctl_$ZK_ID.out"
else
    echo "Stopped zk server $ZK_ID"
fi