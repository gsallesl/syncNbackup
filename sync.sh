#!/usr/bin/env bash

########### config ##############
# Remote host
REMOTE_HOST=myserver

# Remote directory
REMOTE_DIR=/my/full/path/on/remote/host

# Local directory
LOCAL_DIR="."

# Local SSHFS mountpoint
LOCAL_SSHFS_MNT=`mktemp -d /tmp/sync-XXXXXXXX`

# unison logfile
UNISON_LOG=$HOME/.unison.log

# remote backup.sh script
BACKUP_SCRIPT=/path/to/backup/script/on/remote/host/backup.sh

##################################

# making sure we are not going to mess up everything
[ `mountpoint -q $LOCAL_SSHFS_MNT ; echo $?` == "0" ]  && echo " [sync] Something already mounted, cannot proceed!" && exit 1 

# mounting remote point
[ `mountpoint -q $LOCAL_SSHFS_MNT ; echo $?` == "1" ]  && sshfs $REMOTE_HOST:$REMOTE_DIR $LOCAL_SSHFS_MNT

# checking that the mount did occur!
[ `mountpoint -q $LOCAL_SSHFS_MNT ; echo $?` == "1" ]  && echo " [sync] Failure while mounting!" && exit 1

# some breathing time
sleep 1

# the sync!
#unison -logfile $UNISON_LOG -copyonconflict -batch -auto $LOCAL_DIR $LOCAL_SSHFS_MNT
unison -logfile $UNISON_LOG -batch -auto $LOCAL_DIR $LOCAL_SSHFS_MNT

# in case there are conflicts
#unison -logfile $UNISON_LOG $LOCAL_DIR $LOCAL_SSHFS_MNT

# cool down
sleep 1

# umount
fusermount -u $LOCAL_SSHFS_MNT

# making sure we are not going to erase remote files
[ `mountpoint -q $LOCAL_SSHFS_MNT ; echo $?` == "0" ]  && echo " [sync] Remote folder still mounted, cannot erase directory: $LOCAL_SSHFS_MNT" && exit 1 

# erasing temp directory
rmdir $LOCAL_SSHFS_MNT

# Create a revision from the last sync using backup.sh, if there were changes
ssh $REMOTE_HOST $BACKUP_SCRIPT $REMOTE_DIR 
