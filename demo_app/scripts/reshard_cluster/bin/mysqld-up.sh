#!/bin/bash

echo Starting mysqld for all shards

/home/ubuntu/vitess-deployment/bin/mysqld-up-shard-0.sh

/home/ubuntu/vitess-deployment/bin/mysqld-up-shard--80.sh

/home/ubuntu/vitess-deployment/bin/mysqld-up-shard-80-.sh
