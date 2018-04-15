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

TABLET_DIR=vt_0000000201
UNIQUE_ID=201
MYSQL_PORT=17302
WEB_PORT=15302
GRPC_PORT=16302
ALIAS=cell1-0000000201
SHARD=-80
TABLET_TYPE=replica
EXTRA_PARAMS="-enable_semi_sync -enable_replication_reporter"
RDS=0

# Variables used below would be assigned values above this line

export LD_LIBRARY_PATH=${VTROOT}/dist/grpc/usr/local/lib
export PATH=${VTROOT}/bin:${VTROOT}/.local/bin:${VTROOT}/dist/chromedriver:${VTROOT}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/usr/local/go/bin:/usr/local/mysql/bin

case "$MYSQL_FLAVOR" in
  "MySQL56")
    export EXTRA_MY_CNF=$VTROOT/config/mycnf/master_mysql56.cnf
    ;;
  "MariaDB")
    export EXTRA_MY_CNF=$VTROOT/config/mycnf/master_mariadb.cnf
    ;;
  *)
    echo "Please set MYSQL_FLAVOR to MySQL56 or MariaDB."
    exit 1
    ;;
esac

mkdir -p ${VTDATAROOT}/tmp
mkdir -p ${VTDATAROOT}/backups

echo "Starting MySQL for tablet $ALIAS..."


if [ -d $VTDATAROOT/$TABLET_DIR ]; then
    echo "Resuming from existing vttablet dir:"
    echo "    $VTDATAROOT/$TABLET_DIR"
    action='start'
    $VTROOT/bin/mysqlctl \
	-log_dir $VTDATAROOT/tmp \
	-tablet_uid $UNIQUE_ID \
	$DBCONFIG_DBA_FLAGS \
	-mysql_port $MYSQL_PORT \
	$action &
else
    action="init_config"
    $VTROOT/bin/mysqlctl \
	-log_dir $VTDATAROOT/tmp \
	-tablet_uid $UNIQUE_ID \
	$DBCONFIG_DBA_FLAGS \
	-mysql_port $MYSQL_PORT \
	$action &

    action="init -init_db_sql_file $INIT_DB_SQL_FILE"
    $VTROOT/bin/mysqlctl \
	-log_dir $VTDATAROOT/tmp \
	-tablet_uid $UNIQUE_ID \
	$DBCONFIG_DBA_FLAGS \
	-mysql_port $MYSQL_PORT \
	$action &
fi

wait
