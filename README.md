# Google Compute Engine Snapshot

## Overview
* Takes daily snapshot of primary disk without any user input
* Deletes all snapshots that are older than 30 days

## Prerequisite
* cURL must be installed
* The VM must have the sufficient gcloud permissions. e.g. roles/compute.storageAdmin

## Setup
* I run the script from cron.d: `0 * * * * root sh /snapshot.sh`

## Downloading the script and opening in Windows?
 * If you download the script and open it on a Windows machine, that may add windows character's to the file: https://github.com/Forward-Action/google-compute-snapshot/issues/1.
