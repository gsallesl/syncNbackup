#!/usr/local/bin/bash
# backup files using rsync
# GSL - 2015

########### config ##############
# backup path 
HOST_BACKUPS_ROOT=~/backups

# Number of backups to keep
# keep in mind that this tool don't create 
# a new backup is there is no change to backup
NUMBER_OF_BACKUPS=10

# Path to rsync
RSYNC="/usr/local/bin/rsync"

# VERBOSE output -> VERBOSE=1
VERBOSE=0

# Fixed timezone, just to make sure that travels don't mess up your backups
TIMEZONE="Europe/Paris"

# date format used for the backup
date=`TZ=$TIMEZONE date "+%Y-%m-%dT%H:%M:%S"`

# excludes file - this contains a wildcard pattern per line of files to exclude
#EXCLUDES=$HOME/cron/excludes

# Folder that contains symlinks to the most recent backups
BACKUP_POINTERS=".pointers"

# Rsync options
BACKUP_OPTS="-ahz --delete"

##################################

# Rsync --link-dest parameter
BACKUP_LINK_DEST=""

# Directory to backup
backup_source=""

# Directory that contains the resulting backup
backup_dest=""

usage ()
{
	echo "Usage:"
	echo "$0 TARGET"
}


# the argument is the full path to the directory to backup
if [ $# -eq 1 ]
then
	if [ ! -d "$1" ]
	then
		echo "Please specify a path to backup"
		exit 1
	else
		backup_source="$1"
	fi
else
	usage
	exit 1
fi

# Directory that will contain the backups for your directory organized by date
BACKUP_DIR="${HOST_BACKUPS_ROOT}/`basename $backup_source`"

first_run=1

bak_current="${BACKUP_DIR}/${BACKUP_POINTERS}/current"

# test if symbolic link to current backup already exists
if [ -h "$bak_current" ]
then
	if [ -d "`readlink $bak_current`" ]
	then
		first_run=0
		BACKUP_LINK_DEST="--link-dest=`readlink $bak_current`"
	else
		echo  "Your current backup link is pointing nowhere... have you move your backup dir?"
		exit 1
	fi
else
	mkdir -p ${BACKUP_DIR}/${BACKUP_POINTERS}
	echo "${backup_source%/}/" > ${BACKUP_DIR}/origin.txt
fi

# backup to be created
backup_dest=${BACKUP_DIR}/$date

# Respect the rsync syntax
backup_source="${backup_source%/}/"

# Checking for changes to backup against latest backup
if [ $first_run -ne 1 ]
then
	[ $VERBOSE -ne 0 ] && echo "Checking for changes: $RSYNC -n -i $BACKUP_OPTS  $backup_source `readlink $bak_current` | wc -l"
	nb_changes=$($RSYNC -n -i $BACKUP_OPTS  $backup_source `readlink $bak_current` | wc -l)
	if [ $nb_changes -eq 0 ]
	then
		[ $VERBOSE -ne 0 ] && echo "No changes to report"
		exit  0
	fi
fi

# Perform the backup
[ $VERBOSE -ne 0 ] && echo "$RSYNC $BACKUP_OPTS $BACKUP_LINK_DEST $backup_source $backup_dest"
$RSYNC $BACKUP_OPTS $BACKUP_LINK_DEST $backup_source $backup_dest

# Recreate backups directories links
if  [ $first_run -ne  1 ]
then
	oldest_backup_ptr=${BACKUP_DIR}/${BACKUP_POINTERS}/$NUMBER_OF_BACKUPS

	# remove the oldest backup
	[ -h "$oldest_backup_ptr" ] && [ -d "`readlink $oldest_backup_ptr`" ] && rm -rf `readlink $oldest_backup_ptr`

	# shift links
	for i in `seq $NUMBER_OF_BACKUPS -1 2`
	do
		backup_ptr="${BACKUP_DIR}/${BACKUP_POINTERS}/$i"
		newer_backup_ptr="${BACKUP_DIR}/${BACKUP_POINTERS}/$[i-1]"

		[ $VERBOSE -ne 0 ] && [ -h $newer_backup_ptr ] && [ -d "`readlink $newer_backup_ptr`" ] && echo "rm $backup_ptr && ln -s `readlink $newer_backup_ptr` $backup_ptr"
		[ -h $newer_backup_ptr ] && [ -d "`readlink $newer_backup_ptr`" ] && rm -f $backup_ptr && ln -s "`readlink $newer_backup_ptr`" $backup_ptr
	done
	
	[ $VERBOSE -ne 0 ] && echo "rm ${BACKUP_DIR}/${BACKUP_POINTERS}/1 && ln -s `readlink $bak_current` ${BACKUP_DIR}/${BACKUP_POINTERS}/1"
	rm -f ${BACKUP_DIR}/${BACKUP_POINTERS}/1
	ln -s `readlink $bak_current` ${BACKUP_DIR}/${BACKUP_POINTERS}/1
	rm $bak_current
fi
ln -s $backup_dest $bak_current
