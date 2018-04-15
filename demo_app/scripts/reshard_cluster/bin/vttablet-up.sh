#!/bin/bash

# Start mysqld for all shards
/home/ubuntu/vitess-deployment/bin/mysqld-up.sh

echo Starting vttablets for all shards

/home/ubuntu/vitess-deployment/bin/vttablet-up-shard-0.sh

/home/ubuntu/vitess-deployment/bin/vttablet-up-shard--80.sh

/home/ubuntu/vitess-deployment/bin/vttablet-up-shard-80-.sh
