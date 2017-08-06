#!/bin/bash
#
# ./handleMemoriesUploads.sh /srv/uploads/digitalmemories /mnt/external/managedark/digitalmemories /srv/enc/clear/digitalmemories/ /srv/enc/ciphered/digitalmemories/ amazonDrive:/backup/memories false
#
SOURCE_DIR=$1
LOCAL_DEST=$2
ENC_IN=$3
ENC_OUT=$4
RCLONE_SYNC_DEST=$5
SKIP_UPLOAD=$6

STEP=1
function logStep {
    DESC=$1
    echo "Step $STEP: $DESC"
    STEP=$(( $STEP+1  ))
}

echo "Starting files synchronization:"
echo "-------------------------------"

echo "    Source directory: $SOURCE_DIR"
echo "    Local destination directory: $LOCAL_DEST"
echo "    EncFS clear directory: $ENC_IN"
echo "    EncFS ciphered output directory: $ENC_OUT"
echo "    Online backup ciphered destination: $RCLONE_SYNC_DEST"


logStep "Copying contents to local destination $LOCAL_DEST"

time rsync -ua $SOURCE_DIR/* $LOCAL_DEST

logStep "Ciphering content..."

time rsync -ua $SOURCE_DIR/* $ENC_IN

if [ "$SKIP_UPLOAD" == "true" ]; then
    logStep "Skipped upload and clean-up"
    exit 0
fi

logStep "Uploading ciphered contents to online storage: $RCLONE_SYNC_DEST"

/opt/rclone/rclone copy $ENC_OUT $RCLONE_SYNC_DEST

UPLOAD_RESULT=$?

if [ "$UPLOAD_RESULT" == "0" ]; then
    logStep "Files uploaded, cleaning-up temporary ciphered files ..." 
    rm -r $ENC_IN/*
    logStep "... and source contents"
    rm -r $SOURCE_DIR/*
else
    echo "UPLOAD FAILED! Please, clean cipher folders yourself"
    exit $UPLOAD_RESULT
fi