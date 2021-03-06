#!/bin/bash
# Resharding demo script

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

cat << EOF

The first step is to tell Vitess how we want to partition the data. We do this by providing a VSchema definition as follows:

EOF
cat $VSCHEMA_SHARDED
cat <<EOF

We can load this VSchema into Vitess like this:
EOF

run_interactive 'vtctlclient -server ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15999 ApplyVSchema -vschema "$(cat $VSCHEMA_SHARDED)" cell1_keyspace'

cat << EOF

Now we will start vttablets and MySQL processes for shards -80 and 80-.

EOF

cat << EOF

Getting original shard set.

EOF


orig_shards=$(python -c "import json; print ' '.join(json.loads(open('${DIR}/../config/vttablet.json').read())['shard_sets'][0])")
first_orig_shard=$(echo $orig_shards | cut  -d " " -f1)

echo Original shard set = $orig_shards
echo First shard in original shard set = $first_orig_shard

cat << EOF

Read new shard set.

EOF

new_shards=$(python -c "import json; print ' '.join(json.loads(open('${DIR}/../config/vttablet.json').read())['shard_sets'][1])")

echo New shard set = $new_shards

cat << EOF

Now, let us start mysqld (if needed) and vttablets for the new shards using the generated scripts.

EOF

for shard in $new_shards; do
    run_interactive "${DIR}/mysqld-up-shard-${shard}.sh"
    run_interactive "${DIR}/vttablet-up-shard-${shard}.sh"
done

cat << EOF

Now, if we run the following command, we  should be able to see tablets for all old and new shards.

EOF

run_interactive "vtctlclient -server ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15999 ListAllTablets cell1"

cat << EOF
Once the tablets are ready, initialize replication by electing the first master for each of the new shards:
EOF
for shard in $new_shards; do
    tablet=$(vtctlclient -server ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15999 ListShardTablets cell1_keyspace/$shard | head -1 | awk '{print $1}')
    run_interactive "vtctlclient -server ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15999 InitShardMaster -force cell1_keyspace/$shard $tablet"
done

cat << EOF
Now there should be multiple tablets per shard, with one master for each shard:
EOF

run_interactive "vtctlclient -server ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15999 ListAllTablets cell1"

cat << EOF
The new tablets start out empty, so we need to copy everything from the original shard to the two new ones.

We first copy schema:
EOF

for shard in $new_shards; do
    run_interactive "vtctlclient -server ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15999 CopySchemaShard cell1_keyspace/$first_orig_shard cell1_keyspace/$shard"
done

cat << EOF

Next we copy the data. Since the amount of data to copy can be very large, we use a special batch process
called vtworker to stream the data from a single source to multiple destinations, routing each row based on its keyspace_id.

Notice that we only needed to specifiy the source shards: cell1_keyspace/[$orig_shards]
The SplitClone process will automatically figure out which shards to use as the destinations based on the key range that needs to be covered.
In this case, shard 0 covers the entire range, so it identifies -80 and 80- as the destination shards, since they combine to cover the same range.

Next, it will pause replication on one rdonly (offline processing) tablet to serve as a consistent snapshot of the data.
The app can continue without downtime, since live traffic is served by replica and master tablets, which are unaffected.
Other batch jobs will also be unaffected, since they will be served only by the remaining, un-paused rdonly tablets.

Once the copy from the paused snapshot finishes, vtworker turns on filtered replication from the source shard to each destination shard.
This allows the destination shards to catch up on updates that have continued to flow in from the app since the time of the snapshot.

EOF

for shard in $orig_shards; do
    $DIR/vtworker.sh SplitClone cell1_keyspace/$shard
done

cat << EOF

When the destination shards are caught up, they will continue to replicate new updates.
You can see this by looking at the contents of each shard as you add new feed_items to various pages in the Guestbook app.
Shard 0 will see all the feed_items, while the new shards will only see feed_items for pages that live on that shard.

Let us add a few rows to shard 0.

EOF

echo See data on original shard set: $orig_shards:
echo

for shard in $orig_shards; do
    tablet=$(vtctlclient -server ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15999 ListShardTablets cell1_keyspace/$shard | head -1 | awk '{print $1}')
    run_interactive 'vtctlclient -server ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15999 ExecuteFetchAsDba $tablet "SELECT count(*) FROM feed_items"'
done

echo See data on new shard set: $new_shards:
echo

for shard in $new_shards; do
    tablet=$(vtctlclient -server ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15999 ListShardTablets cell1_keyspace/$shard | head -1 | awk '{print $1}')
    run_interactive 'vtctlclient -server ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15999 ExecuteFetchAsDba $tablet "SELECT count(*) FROM feed_items"'
done

cat << EOF

Now let us check copied data integrity

The vtworker batch process has another mode that will compare the source and destination
to ensure all the data is present and correct.

EOF

for shard in $new_shards; do
    echo for $shard
    $DIR/vtworker.sh SplitDiff cell1_keyspace/$shard
done

cat << EOF

Now we are ready to switch over to serving from the new shards.
The MigrateServedTypes command lets you do this one tablet type at a time, and even one cell at a time.
The process can be rolled back at any point until the master is switched over.
EOF

for shard in $orig_shards; do
    run_interactive "vtctlclient -server ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15999 MigrateServedTypes cell1_keyspace/$shard rdonly"

    run_interactive "vtctlclient -server ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15999 MigrateServedTypes cell1_keyspace/$shard replica"

    run_interactive "vtctlclient -server ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15999 MigrateServedTypes cell1_keyspace/$shard master"
done


cat << EOF

During the master migration, the original shard master will first stop accepting updates.
Then the process will wait for the new shard masters to fully catch up on filtered replication before allowing them to begin serving.
Since filtered replication has been following along with live updates, there should only be a few seconds of master unavailability.

When the master traffic is migrated, the filtered replication will be stopped.
Data updates will be visible on the new shards, but not on the original shard.
See it for yourself: Let us add a few rows and then inspect the database content.

EOF

echo See data on original shard set: $orig_shards:
echo "(no updates visible since we migrated away from it):"
echo
echo

for shard in $orig_shards; do
    tablet=$(vtctlclient -server ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15999 ListShardTablets cell1_keyspace/$shard | head -1 | awk '{print $1}')
    run_interactive 'vtctlclient -server ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15999 ExecuteFetchAsDba $tablet "SELECT count(*) FROM feed_items"'
done

echo See data on new shard set: $new_shards:
echo

for shard in $new_shards; do
    tablet=$(vtctlclient -server ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15999 ListShardTablets cell1_keyspace/$shard | head -1 | awk '{print $1}')
    run_interactive 'vtctlclient -server ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15999 ExecuteFetchAsDba $tablet "SELECT count(*) FROM feed_items"'
done

cat << EOF

Now that all traffic is being served from the new shards, we can remove the original shard set.
Fist we shut down the vttablets for the unused shards.

EOF

for shard in $orig_shards; do
    run_interactive "$DIR/vttablet-down-shard-${shard}.sh"
    run_interactive "$DIR/mysqld-down-shard-${shard}.sh"
done

cat << EOF

Then we can delete the now-empty shard-set:

EOF

for shard in $orig_shards; do
    run_interactive "vtctlclient -server ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15999 DeleteShard -recursive cell1_keyspace/$shard"
done

echo
echo Congratulations, you have succesfully resharded your database.
echo Look at http://ec2-34-208-78-29.us-west-2.compute.amazonaws.com:15000/ and verify that you only see shards 80- and -80.
echo
