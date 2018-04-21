#!/bin/bash

export VTDATAROOT=/home/ubuntu/vtdataroot
export VTROOT=/home/ubuntu
export VTTOP=/home/ubuntu/src/github.com/youtube/vitess
export VT_MYSQL_ROOT=/usr/local/mysql
export MYSQL_FLAVOR=MariaDB

MYSQL_AUTH_PARAM=""

DBNAME=vt_cell1_keyspace
KEYSPACE=cell1_keyspace
TOPOLOGY_FLAGS="-topo_implementation zk2 -topo_global_server_address ec2-34-208-78-29.us-west-2.compute.amazonaws.com:21811,ec2-34-213-57-41.us-west-2.compute.amazonaws.com:21811,ec2-34-208-152-137.us-west-2.compute.amazonaws.com:21811 -topo_global_root /vitess/global"
DBCONFIG_DBA_FLAGS="-db-config-dba-uname vt_dba -db-config-dba-charset utf8"
DBCONFIG_FLAGS="-db-config-dba-uname vt_dba -db-config-dba-charset utf8 -db-config-allprivs-uname vt_allprivs -db-config-allprivs-charset utf8 -db-config-app-uname vt_app -db-config-app-charset utf8 -db-config-repl-uname vt_repl -db-config-repl-charset utf8 -db-config-filtered-uname vt_filtered -db-config-filtered-charset utf8"
INIT_DB_SQL_FILE=/home/ubuntu/vitess-deployment/config/init_db.sql
VTCTLD_HOST=ec2-34-208-78-29.us-west-2.compute.amazonaws.com
VTCTLD_WEB_PORT=15000
HOSTNAME=ec2-34-213-57-41.us-west-2.compute.amazonaws.com

TABLET_DIR=vt_0000000301
UNIQUE_ID=301
MYSQL_PORT=17402
WEB_PORT=15402
GRPC_PORT=16402
ALIAS=cell1-0000000301
SHARD=80-
TABLET_TYPE=replica
EXTRA_PARAMS="-enable_semi_sync -enable_replication_reporter"
RDS=0

# Variables used below would be assigned values above this line

echo "Stopping vttablet for $ALIAS..."
pid=`cat $VTDATAROOT/$TABLET_DIR/vttablet.pid`
kill $pid

while ps -p $pid > /dev/null; do sleep 1; done

