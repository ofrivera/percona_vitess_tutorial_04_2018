
These scripts are generated using https://github.com/jvaidya/vitess-tools/tree/master/deployment_helper
They work with the four-host ec2 cluster that they were generated for.

To start a cluster, run:

./start_cluster/bin/start_cluster.sh

After you have the cluster running, to run the resharding workflow, run:

./reshard_cluster/bin/run_sharding_workflow.sh
