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
HOSTNAME=ec2-34-213-241-157.us-west-2.compute.amazonaws.com

TABLET_DIR=vt_0000000101
UNIQUE_ID=101
MYSQL_PORT=17202
WEB_PORT=15202
GRPC_PORT=16202
ALIAS=cell1-0000000101
SHARD=0
TABLET_TYPE=replica
EXTRA_PARAMS="-enable_semi_sync -enable_replication_reporter"
RDS=0

# Variables used below would be assigned values above this line
BACKUP_PARAMS_S3="-backup_storage_implementation s3 -s3_backup_aws_region us-west-2 -s3_backup_storage_bucket vtlabs-vtbackup"
BACKUP_PARAMS_FILE="-backup_storage_implementation file -file_backup_storage_root $VTDATAROOT/backups -restore_from_backup"

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

echo "Starting vttablet for $ALIAS..."

$VTROOT/bin/vttablet \
    $TOPOLOGY_FLAGS \
    -log_dir $VTDATAROOT/tmp \
    -tablet-path $ALIAS \
    -tablet_hostname "$HOSTNAME" \
    -init_keyspace $KEYSPACE \
    -init_shard $SHARD \
    -init_tablet_type $TABLET_TYPE \
    -init_db_name_override $DBNAME \
    -mycnf_mysql_port $MYSQL_PORT \
    -health_check_interval 5s \
    $BACKUP_PARAMS_FILE \
    -binlog_use_v3_resharding_mode \
    -port $WEB_PORT \
    -grpc_port $GRPC_PORT \
    -service_map 'grpc-queryservice,grpc-tabletmanager,grpc-updatestream' \
    -pid_file $VTDATAROOT/$TABLET_DIR/vttablet.pid \
    -vtctld_addr http://${VTCTLD_HOST}:${VTCTLD_WEB_PORT}/ \
    $DBCONFIG_FLAGS \
    ${MYSQL_AUTH_PARAM} ${EXTRA_PARAMS}\
    > $VTDATAROOT/$TABLET_DIR/vttablet.out 2>&1 &

echo "Access tablet $ALIAS at http://$HOSTNAME:$WEB_PORT/debug/status"
