#!/bin/bash

# First invoked by sdcard/write
mountpartitions(){
  # Partition the sd card
  # There's nothing to do here, because all this is made with dd
  echo "No extra partition work has to be done. Continuing..."
}

# Invoked by sdcard/write
cleanup(){
  case $MACHINENAME in
    rpi|rpi-2|rpi-3)
      umount_root;;
    *)
      exit;;
  esac
}

extract_archive(){
  echo "Extracting Archive using unzip"
  unzip $1 -d $2
}


# Takes an URL (.img.zip file) to download an the name of the downloaded file. Assumes that the extracted and the downloaded file has the same names except for the extension
generaldownload(){

  # Install unzip and partprobe if not present
  require unzip unzip
  require partprobe partprobe

  # We can't write this .img file to /tmp because /tmp has a limit of 462MB
  DLDIR=/etc/tmp/koa-$(echo $1 | md5sum | awk '{print $1}')
  DL_LINK=$1
  IMAGE_NAME=$2
  ROOT_PARTITION=$3
  ZIPFILE=$(basename $DL_LINK)

  # Ensure this page is present
  mkdir -p $DLDIR

  # Do not overwrite the .img.zip file if that release already exists
  if [[ ! -f $DLDIR/$ZIPFILE ]]; then
    curl -sSL $DL_LINK > $DLDIR/$ZIPFILE
  else
    echo "No need to download archive, archive exists"
  fi

  # Do not overwrite the .img file if that release already exists
  if [[ ! -f $DLDIR/$IMAGE_NAME ]]; then
    extract_archive $DLDIR/$ZIPFILE $DLDIR
  else
    echo "No need to extract archive, image exists"
  fi

  dd if=$DLDIR/$IMAGE_NAME of=$SDCARD bs=4M

  sync

  # Clear old mounts, if any
  umount $ROOT_PARTITION
  # Force kernel to reload partitions
  partprobe

  mount $ROOT_PARTITION $ROOT
  # Will take ~9 mins on a Pi
}

umount_root(){
  umount $ROOT
}
