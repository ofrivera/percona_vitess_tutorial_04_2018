#!/bin/bash
# This script starts a local cluster.

SCHEMA_DIR=/home/ubuntu/src/github.com/rafael/percona_vitess_tutorial_04_2018/demo_app/schemas
SCHEMA_FILE=${SCHEMA_DIR}/schema.sql
VSCHEMA_SHARDED=${SCHEMA_DIR}/vschema_sharded.json
VSCHEMA_UNSHARDED=${SCHEMA_DIR}/vschema_unsharded.json

function run_interactive()
{
    command=$1
    prompt=${2:-"Run this command? (Y/n):"}
    echo $command
    read -p "$prompt" response
    if echo "$response" | grep -iq "^n" ; then
	echo Not running: $command
    else
	eval $command
    fi
}

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo
echo This script will walk you through starting a vitess cluster.
echo
echo Servers in a Vitess cluster find each other by looking for dynamic configuration data stored in a distributed lock service.
echo After the ZooKeeper cluster is running, we only need to tell each Vitess process how to connect to ZooKeeper.
echo Then, each process can find all of the other Vitess processes by coordinating via ZooKeeper.

echo Each of our scripts automatically uses the TOPOLOGY_FLAGS environment variable to point to the global ZooKeeper instance.
echo The global instance in turn is configured to point to the local instance.
echo This demo assumes that they are both hosted in the same ZooKeeper service.

echo
run_interactive "$DIR/zk-up.sh"

echo
echo The vtctld server provides a web interface that displays all of the coordination information stored in ZooKeeper.
echo
run_interactive "$DIR/vtctld-up.sh"

echo
echo Open http://ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15000 to verify that vtctld is running.
echo "There won't be any information there yet, but the menu should come up, which indicates that vtctld is running."

echo The vtctld server also accepts commands from the vtctlclient tool, which is used to administer the cluster.
echo "Note that the port for RPCs (in this case 15999) is different from the web UI port (15000)."
echo These ports can be configured with command-line flags, as demonstrated in vtctld-up.sh.
echo
echo
echo The vttablet-up.sh script brings up vttablets, for all shards
echo
run_interactive "$DIR/vttablet-up.sh"
echo
echo Next, designate one of the tablets to be the initial master.
echo Vitess will automatically connect the other slaves' mysqld instances so that they start replicating from the master's mysqld.
echo This is also when the default database is created. Our keyspace is named cell1_keyspace, and our MySQL database is named vt_cell1_keyspace.
echo

orig_shards=$(python -c "import json; print ' '.join(json.loads(open('/home/ubuntu/vitess-deployment/config/vttablet.json').read())['shard_sets'][0])")
first_orig_shard=$(echo $orig_shards | cut  -d " " -f1)
num_orig_shards=$(echo $orig_shards | wc -w)

for shard in $orig_shards; do
    tablet=$(vtctlclient -server ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15999 ListShardTablets cell1_keyspace/$shard | head -1 | awk '{print $1}')
    run_interactive "vtctlclient -server ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15999 InitShardMaster -force cell1_keyspace/$shard $tablet"
done

echo
echo After running this command, go back to the Shard Status page in the vtctld web interface.
echo When you refresh the page, you should see that one vttablet is the master and the other two are replicas.
echo
echo You can also see this on the command line:
echo
run_interactive "vtctlclient -server ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15999 ListAllTablets cell1"
echo
echo The vtctlclient tool can be used to apply the database schema across all tablets in a keyspace.
echo The following command creates the table defined in the create_test_table.sql file
run_interactive 'vtctlclient -server ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15999 ApplySchema -sql "$(cat $SCHEMA_FILE)" cell1_keyspace'
echo
echo "Now that the initial schema is applied, it's a good time to take the first backup. This backup will be used to automatically restore any additional replicas that you run, before they connect themselves to the master and catch up on replication. If an existing tablet goes down and comes back up without its data, it will also automatically restore from the latest backup and then resume replication."

for shard in $orig_shards; do
    tablet=$(vtctlclient -server ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15999 ListShardTablets cell1_keyspace/$shard | head -3 | tail -1 | awk '{print $1}')
    run_interactive "vtctlclient -server ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15999 Backup $tablet"
done


echo
echo After the backup completes, you can list available backups for the shards:

for shard in $orig_shards; do
    run_interactive "vtctlclient -server ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15999 ListBackups cell1_keyspace/$shard"
done


echo
echo
echo Note: In this example setup, backups are stored at $VTDATAROOT/backups. In a multi-server deployment, you would usually mount an NFS directory there. You can also change the location by setting the -file_backup_storage_root flag on vtctld and vttablet

echo Initialize Vitess Routing Schema
echo We will apply the following VSchema:
cat $VSCHEMA_UNSHARDED
echo
run_interactive 'vtctlclient -server ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15999 ApplyVSchema -vschema "$(cat $VSCHEMA_UNSHARDED)" cell1_keyspace'
echo Start vtgate

echo Vitess uses vtgate to route each client query to the correct vttablet. This local example runs a single vtgate instance, though a real deployment would likely run multiple vtgate instances to share the load.

run_interactive "$DIR/vtgate-up.sh"

echo
echo Congratulations, your local cluster is now up and running.
echo
cat << EOF
You can now explore the cluster:

    Access vtctld web UI at http://ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15000
    Send commands to vtctld with: vtctlclient -server ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15999 ...
    Try "vtctlclient -server ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15999 help".

	Access tablet cell1-0000000100 at http://ec2-34-208-152-137.us-west-2.compute.amazonaws.com:15201/debug/status
	Access tablet cell1-0000000101 at http://ec2-34-213-241-157.us-west-2.compute.amazonaws.com:15202/debug/status
	Access tablet cell1-0000000102 at http://ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15203/debug/status
	Access tablet cell1-0000000103 at http://ec2-34-213-57-41.us-west-2.compute.amazonaws.com:15204/debug/status
	Access tablet cell1-0000000104 at http://ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15205/debug/status

    Access vtgate at http://ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15001/debug/status
    Connect to vtgate either at grpc_port or mysql_port and run queries against vitess.

    Note: Vitess binaries write write logs under $VTDATAROOT/tmp.
EOF
