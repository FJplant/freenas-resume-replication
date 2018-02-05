SSH=/usr/local/bin/ssh
DATASET_OR_ZVOL=$1
REMOTE_IP=$2
REMOTE_PORT=$3
TARGET_LOCATION=$4
SSH_CMD_OPTIONS="-ononeenabled=yes -ononeswitch=yes -i /data/ssh/replication -o BatchMode=yes -o StrictHostKeyChecking=yes -o ConnectTimeout=7"
RECEIVE_RESUME_TOKEN=""
ZFS_EXIT_CODE=1

echo 'DATASET_OR_ZVOL='$1
echo 'TARGET_IP='$2
echo 'TARGET_PORT='$3
echo 'TARGET_LOCATION='$4

/sbin/zfs send -V -p -i $DATASET_OR_ZVOL | /usr/local/bin/pigz | /usr/local/bin/pipewatcher $$ | /usr/local/bin/ssh $SSH_CMD_OPTIONS -p $REMOTE_PORT $REMOTE_IP "/usr/bin/env pigz -d | /sbin/zfs receive -F -d 'backup-pool/replication-local' && echo Succeeded"
$ZFS_EXIT_CODE=$?

while [ $ZFS_EXIT_CODE -gt 0 ]
do
    RECEIVE_RESUME_TOKEN=`$SSH $SSH_CMD_OPTIONS -p $REMOTE_PORT $REMOTE_IP "zfs get -p receive_resume_token | grep $DATASET_OR_ZVOL" 2> /dev/null | awk '{print $3'}`
    echo '['`date`']Recieved resume token: '$RECEIVE_RESUME_TOKEN
    echo '['`date`']Resuming replication...'
    /sbin/zfs send -t $RECEIVE_RESUME_TOKEN | /usr/local/bin/pigz | /usr/local/bin/pipewatcher $$ | /usr/local/bin/ssh $SSH_CMD_OPTIONS -p $REMOTE_PORT $REMOTE_IP "/usr/bin/env pigz -d | /sbin/zfs receive -s -F -d 'eugene-pool/replication-remote' && echo Succeeded"
    ZFS_EXIT_CODE=$?
    echo '['`date`']Communication broken, ZFS_EXIT_CODE ='$ZFS_EXIT_CODE
    sleep 5
done
