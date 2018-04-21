#!/bin/bash

echo Starting tablets for shard "80-" ...

/home/ubuntu/vitess-deployment/bin/run_script_on_host.sh ec2-34-208-152-137.us-west-2.compute.amazonaws.com /home/ubuntu/vitess-deployment/bin/ec2-34-208-152-137.us-west-2.compute.amazonaws.com/vttablet-up-instance-300.sh

/home/ubuntu/vitess-deployment/bin/run_script_on_host.sh ec2-34-213-57-41.us-west-2.compute.amazonaws.com /home/ubuntu/vitess-deployment/bin/ec2-34-213-57-41.us-west-2.compute.amazonaws.com/vttablet-up-instance-301.sh

/home/ubuntu/vitess-deployment/bin/run_script_on_host.sh ec2-34-213-241-157.us-west-2.compute.amazonaws.com /home/ubuntu/vitess-deployment/bin/ec2-34-213-241-157.us-west-2.compute.amazonaws.com/vttablet-up-instance-302.sh

/home/ubuntu/vitess-deployment/bin/run_script_on_host.sh ec2-34-208-78-29.us-west-2.compute.amazonaws.com /home/ubuntu/vitess-deployment/bin/ec2-34-208-78-29.us-west-2.compute.amazonaws.com/vttablet-up-instance-303.sh

/home/ubuntu/vitess-deployment/bin/run_script_on_host.sh ec2-34-208-78-29.us-west-2.compute.amazonaws.com /home/ubuntu/vitess-deployment/bin/ec2-34-208-78-29.us-west-2.compute.amazonaws.com/vttablet-up-instance-304.sh
