#!/bin/bash

### User Pass Mysql ###
USER=root
PASS=root_password
#DBNAME=project_sql
BACKUP_DIR="/root/backup"
DST_HOST="user@host"
REMOTE_DST_DIR="/root/backup"
BACKUP_DAILY=true # if set to false backup will not work
BACKUP_WEEKLY=true # if set to false backup will not work
BACKUP_MONTHLY=true # if set to false backup will not work
BACKUP_RETENTION_DAILY=3
BACKUP_RETENTION_WEEKLY=3
BACKUP_RETENTION_MONTHLY=3
BACKUP_MODE='local-only' ## Available option ( 'local-only' | 'remote-only' | 'local-remote' )

###Test daily weekly or monthly###
MONTH=`date +%d`
DAYWEEK=`date +%u`

if [[ ( $MONTH -eq 1 ) && ( $BACKUP_MONTHLY == true ) ]];
        then
        FN='monthly'
elif [[ ( $DAYWEEK -eq 7 ) && ( $BACKUP_WEEKLY == true ) ]];
        then
        FN='weekly'
elif [[ ( $DAYWEEK -lt 7 ) && ( $BACKUP_DAILY == true ) ]];
        then
        FN='daily'
fi


DATE=$FN-xtrabackup-`date +"%Y%m%d-%H%M"`

function local_remote
{
	cd $BACKUP_DIR
	mkdir -p $DATE
	innobackupex --user=$USER --password=$PASS --no-timestamp $DATE
	tar -Jcvf $DATE.tar.xz $DATE
	rm -Rf $DATE
	ls -t | grep daily | grep xtrabackup | sed -e 1,"$BACKUP_RETENTION_DAILY"d | xargs -d '\n' rm -R > /dev/null 2>&1
	ls -t | grep weekly | grep xtrabackup | sed -e 1,"$BACKUP_RETENTION_WEEKLY"d | xargs -d '\n' rm -R > /dev/null 2>&1
	ls -t | grep monthly | grep xtrabackup | sed -e 1,"$BACKUP_RETENTION_MONTHLY"d | xargs -d '\n' rm -R > /dev/null 2>&1
	rsync -avh --delete $BACKUP_DIR/ $DST_HOST:$REMOTE_DST_DIR
}

function local_only
{
	cd $BACKUP_DIR
	mkdir -p $DATE
	innobackupex --user=$USER --password=$PASS --no-timestamp $DATE
        innobackupex --apply-log $DATE
        #echo "Apply log sukses" > success.txt
	tar -Jcvf $DATE.tar.xz $DATE
	rm -Rf $DATE
	ls -t | grep daily | grep xtrabackup | sed -e 1,"$BACKUP_RETENTION_DAILY"d | xargs -d '\n' rm -R > /dev/null 2>&1
	ls -t | grep weekly | grep xtrabackup | sed -e 1,"$BACKUP_RETENTION_WEEKLY"d | xargs -d '\n' rm -R > /dev/null 2>&1
	ls -t | grep monthly | grep xtrabackup | sed -e 1,"$BACKUP_RETENTION_MONTHLY"d | xargs -d '\n' rm -R > /dev/null 2>&1
}

function remote_only
{
	cd $BACKUP_DIR
	mkdir -p $DATE
	innobackupex --user=$USER --password=$PASS --no-timestamp $DATE
	tar -Jcvf $DATE.tar.xz $DATE
	rm -Rf $DATE
	rsync -avh --remove-source-files $BACKUP_DIR/ $DST_HOST:$REMOTE_DST_DIR
	ssh -t -t $DST_HOST "cd $REMOTE_DST_DIR ; ls -t | grep daily | grep xtrabackup | sed -e 1,"$BACKUP_RETENTION_DAILY"d | xargs -d '\n' rm -R > /dev/null 2>&1"
	ssh -t -t $DST_HOST "cd $REMOTE_DST_DIR ; ls -t | grep daily | grep xtrabackup | sed -e 1,"$BACKUP_RETENTION_WEEKLY"d | xargs -d '\n' rm -R > /dev/null 2>&1"
	ssh -t -t $DST_HOST "cd $REMOTE_DST_DIR ; ls -t | grep daily | grep xtrabackup | sed -e 1,"$BACKUP_RETENTION_MONTHLY"d | xargs -d '\n' rm -R > /dev/null 2>&1"
}

if [ $BACKUP_MODE == local-remote ]; then
	if [[ ( $BACKUP_DAILY == true ) && ( ! -z "$BACKUP_RETENTION_DAILY" ) && ( $BACKUP_RETENTION_DAILY -ne 0 ) && ( $FN == daily ) ]]; then
		local_remote
	fi
	if [[ ( $BACKUP_WEEKLY == true ) && ( ! -z "$BACKUP_RETENTION_WEEKLY" ) && ( $BACKUP_RETENTION_WEEKLY -ne 0 ) && ( $FN == weekly ) ]]; then
		local_remote
	fi
	if [[ ( $BACKUP_MONTHLY == true ) && ( ! -z "$BACKUP_RETENTION_MONTHLY" ) && ( $BACKUP_RETENTION_MONTHLY -ne 0 ) && ( $FN == monthly ) ]]; then
		local_remote
	fi
elif [ $BACKUP_MODE == local-only ]; then
	if [[ ( $BACKUP_DAILY == true ) && ( ! -z "$BACKUP_RETENTION_DAILY" ) && ( $BACKUP_RETENTION_DAILY -ne 0 ) && ( $FN == daily ) ]]; then
		local_only
	fi
	if [[ ( $BACKUP_WEEKLY == true ) && ( ! -z "$BACKUP_RETENTION_WEEKLY" ) && ( $BACKUP_RETENTION_WEEKLY -ne 0 ) && ( $FN == weekly ) ]]; then
		local_only
	fi
	if [[ ( $BACKUP_MONTHLY == true ) && ( ! -z "$BACKUP_RETENTION_MONTHLY" ) && ( $BACKUP_RETENTION_MONTHLY -ne 0 ) && ( $FN == monthly ) ]]; then
		local_only
	fi
elif [ $BACKUP_MODE == remote-only ]; then
	if [[ ( $BACKUP_DAILY == true ) && ( ! -z "$BACKUP_RETENTION_DAILY" ) && ( $BACKUP_RETENTION_DAILY -ne 0 ) && ( $FN == daily ) ]]; then
		remote_only
	fi
	if [[ ( $BACKUP_WEEKLY == true ) && ( ! -z "$BACKUP_RETENTION_WEEKLY" ) && ( $BACKUP_RETENTION_WEEKLY -ne 0 ) && ( $FN == weekly ) ]]; then
		remote_only
	fi
	if [[ ( $BACKUP_MONTHLY == true ) && ( ! -z "$BACKUP_RETENTION_MONTHLY" ) && ( $BACKUP_RETENTION_MONTHLY -ne 0 ) && ( $FN == monthly ) ]]; then
		remote_only
	fi
fi

