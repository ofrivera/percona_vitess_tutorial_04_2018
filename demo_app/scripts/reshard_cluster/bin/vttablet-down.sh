#!/bin/bash

echo Stopping vttablets for all shards

/home/ubuntu/vitess-deployment/bin/vttablet-down-shard-0.sh

/home/ubuntu/vitess-deployment/bin/vttablet-down-shard--80.sh

/home/ubuntu/vitess-deployment/bin/vttablet-down-shard-80-.sh

# Stop mysqld for all shards
/home/ubuntu/vitess-deployment/bin/mysqld-down.sh
