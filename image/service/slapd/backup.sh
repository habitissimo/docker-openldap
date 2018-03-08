#!/bin/bash -e
TIMESTAMP=`date +%Y%m%d`
BACKUPS_FOLDER="/var/backups"

CONFIG_BACKUP_FILE="config-$TIMESTAMP.ldif"
DB_BACKUP_FILE="db-$TIMESTAMP.ldif"

LAST_BACKUP_FILE="$BACKUPS_FOLDER/last_backup"


function backup {
    slapcat -n 0 -l "$BACKUPS_FOLDER/$CONFIG_BACKUP_FILE"
    slapcat -n 1 -l "$BACKUPS_FOLDER/$DB_BACKUP_FILE"
    echo $TIMESTAMP > $LAST_BACKUP_FILE
}

function get_last_backup_date {
    cat $LAST_BACKUP_FILE || echo "NO-BACKUPS"
}

function put_to_s3 {
    export AWS_ACCESS_KEY_ID=$S3_KEY
    export AWS_SECRET_ACCESS_KEY=$S3_SECRET
    aws s3 cp "${1}/${2}" "s3://${S3_BUCKET}/${S3_PATH}/${2}"
}

function upload_backups {
    put_to_s3 $BACKUPS_FOLDER $CONFIG_BACKUP_FILE
    put_to_s3 $BACKUPS_FOLDER $DB_BACKUP_FILE
}

if [ "${LDAP_BACKUP,,}" == "true" ]; then
    backup
    last_backup=$(get_last_backup_date)
    if [ "${last_backup,,}" != $TIMESTAMP ]|| [ "$1" == "-f" ]; then
        upload_backups
    fi
fi