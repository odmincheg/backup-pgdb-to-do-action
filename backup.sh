#!/bin/sh -l
#----------------------------------------
# VARS
#----------------------------------------

CURRENTDATE=`date +%d%m%y%H%M`
BACKUP_DIR="backups"
RESTORE_DIR="restore"
INPUT_PASS=""
EXTRA_SCRIPT=""

#----------------------------------------
# DigitalOcean space section
#----------------------------------------
echo "Credentials provided"

touch ~/.s3cfg

echo "[default]
access_key=$INPUT_SPACE_ACCESS_KEY_ID
secret_key=$INPUT_SPACE_SECRET_ACCESS_KEY
bucket_location=US
host_base=$INPUT_SPACE_REGION.digitaloceanspaces.com
host_bucket=$INPUT_SPACE_NAME.$INPUT_SPACE_REGION.digitaloceanspaces.com
proxy_host =
proxy_port = 0
use_http_expect = False
use_https = True
server_side_encryption = False" > ~/.s3cfg
git clone https://github.com/s3tools/s3cmd

#----------------------------------------
# Prepare to recipe to backup
#----------------------------------------
echo "Generating folder for backup"
if [ ! -d ./$BACKUP_DIR/ ]; then
    mkdir -p $BACKUP_DIR
fi

if [ "$INPUT_DB_ACTION" = "backup" ]; then
  echo "Checking provided credentials for database server"
  if [[ "$INPUT_DB_USER" = "" || "$INPUT_DB_NAME" = "" ]]; then
    echo 'db_user and db_name should not be empty, Please specify.'
    exit 1
  fi
  echo "Credentials for database server provided"

  if [[ "$INPUT_SPACE_ACCESS_KEY_ID" = "" || "$INPUT_SPACE_SECRET_ACCESS_KEY" = "" || "$INPUT_SPACE_NAME" = "" ]]; then
    echo 'space_access_key_id and space_secret_access_key and space_name should not be empty, Please specify.'
    exit 1
  fi
  
  if [ "$INPUT_DB_TYPE" = "postgres" ]; then
    FILENAME=$INPUT_DB_TYPE-$INPUT_DB_NAME.$CURRENTDATE.pgsql.gz
    INPUT_DB_PORT="${INPUT_DB_PORT:-5432}"
    INPUT_ARGS="${INPUT_ARGS} -C --column-inserts"
    export PGPASSWORD="$INPUT_DB_PASS"
    echo "Creating database dump"
    pg_dump -U $INPUT_DB_USER -h $INPUT_DB_HOST -p $INPUT_DB_PORT $INPUT_ARGS $INPUT_DB_NAME | gzip -9 > $BACKUP_DIR/$FILENAME
    echo "Db dump completed. File: $FILENAME"
    echo "Starting upload to DigitalOcean space"
    python3 ./s3cmd/s3cmd put $BACKUP_DIR/$FILENAME s3://$INPUT_SPACE_NAME/$BACKUP_DIR/$FILENAME
  fi
fi

if [ "$INPUT_DB_ACTION" = "restore" ]; then
  if [ ! -d ./$RESTORE_DIR/ ]; then
    mkdir -p $RESTORE_DIR
  fi

  if [ "$INPUT_DB_TYPE" = "postgres" ]; then
    FILEURL=$INPUT_DB_BACKUP_URL
    INPUT_DB_PORT="${INPUT_DB_PORT:-5432}"
    INPUT_ARGS="${INPUT_ARGS} -C --column-inserts"
    export PGPASSWORD="$INPUT_DB_PASS"
    echo "Downloading and extracting backup..."
    wget -O $RESTORE_DIR/db_backup.pgsql.gz $FILEURL
    gunzip -c $RESTORE_DIR/db_backup.pgsql.gz > $RESTORE_DIR/db_backup.pgsql
    echo "Restoring backup..."
    pg_restore -U $INPUT_DB_USER -h $INPUT_DB_HOST -p $INPUT_DB_PORT $INPUT_ARGS $INPUT_DB_NAME < $RESTORE_DIR/ && echo "Database restored"
  fi
fi
echo "Upload to DigitalOcean space completed"
