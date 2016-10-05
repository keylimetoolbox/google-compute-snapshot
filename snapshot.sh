#!/usr/bin/env bash
export PATH=$PATH:/usr/local/bin/:/usr/bin

#
# CREATE DAILY SNAPSHOT
#

# Set this to the number of days of snapshots you want to keep
RETENTION_DAYS=32

# get the name for this vm
INSTANCE_NAME="$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/hostname" -H "Metadata-Flavor: Google")"
# strip out the instanc name from the fullly qualified domain name the google returns
INSTANCE_NAME="${INSTANCE_NAME%%.*}"

# get the zone that this vm is in
INSTANCE_ZONE="$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/zone" -H "Metadata-Flavor: Google")"
# strip out the zone from the full URI that google returns
INSTANCE_ZONE="${INSTANCE_ZONE##*/}"

# create a datetime stamp for filename
DATE_TIME="$(date "+%s")"

# get the name of each attaced device
DEVICE_LIST="$(gcloud compute disks list --filter users~${INSTANCE_NAME} --format='value(name)')"

# create the snapshots
echo "${DEVICE_LIST}" | while read DEVICE_NAME
do
  echo "$(gcloud compute disks snapshot ${DEVICE_NAME} --snapshot-names gcs-${DEVICE_NAME}-${DATE_TIME} --zone ${INSTANCE_ZONE} --quiet)"
done

#
# DELETE OLD SNAPSHOTS (OLDER THAN 30 DAYS)
#

# get a list of existing snapshots, that were created by this process (gcs-), for this vm disk (INSTANCE_NAME)
SNAPSHOT_LIST="$(gcloud compute snapshots list --regexp "(.*gcs-.*)|(.*-${INSTANCE_NAME}-.*)" --uri)"

# loop through the snapshots
echo "${SNAPSHOT_LIST}" | while read line
do

  # get the snapshot name from full URL that google returns
  SNAPSHOT_NAME="${line##*/}"

  # get the date that the snapshot was created
  SNAPSHOT_DATETIME="$(gcloud compute snapshots describe ${SNAPSHOT_NAME} | grep "creationTimestamp" | cut -d " " -f 2 | cut -d '-' -f 1-3 | tr -d \')"

  # format the date
  SNAPSHOT_DATETIME="$(date -d ${SNAPSHOT_DATETIME} +%Y%m%d)"

  # get the expiry date for snapshot deletion
  SNAPSHOT_EXPIRY="$(date -d "-$RETENTION_DAYS days" +"%Y%m%d")"

   # check if the snapshot is older than expiry date
  if [ $SNAPSHOT_EXPIRY -ge $SNAPSHOT_DATETIME ];
  then
	  # delete the snapshot
    echo "$(gcloud compute snapshots delete ${SNAPSHOT_NAME} --quiet)"
  fi
done
