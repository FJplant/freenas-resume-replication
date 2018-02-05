#!/bin/bash
SSH=/usr/local/bin/ssh
REMOTE_IP=192.168.0.203
REMOTE_PORT=22
DATASET_OR_ZVOL=nfs-vmstore-01
SSH_CMD_OPTIONS="-ononeenabled=yes -ononeswitch=yes -i /data/ssh/replication -o BatchMode=yes -o StrictHostKeyChecking=yes -o ConnectTimeout=7"

RECEIVE_RESUME_TOKEN=`$SSH $SSH_CMD_OPTIONS -p $REMOTE_PORT $REMOTE_IP "zfs get -p receive_resume_token | grep $DATASET_OR_ZVOL" 2> /dev/null | awk '{print $3'}`

echo $RECEIVE_RESUME_TOKEN
