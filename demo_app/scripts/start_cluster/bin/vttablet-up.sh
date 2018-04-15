#!/bin/bash

# Start mysqld for all shards
/home/ubuntu/vitess-deployment/bin/mysqld-up-shard-0.sh

echo Starting vttablets for all shards

/home/ubuntu/vitess-deployment/bin/vttablet-up-shard-0.sh
