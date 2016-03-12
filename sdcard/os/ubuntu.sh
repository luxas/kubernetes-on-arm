#!/bin/bash
ODROID_C2_DOWNLOAD_LINK=https://s3.amazonaws.com/odroid-c2/odroid-c2-base.img.tar.gz
ODROID_C2_IMAGE_NAME=odroid-c2-base.img

. ./os/debian.sh

cleanup(){
  case $MACHINENAME in
    odroid-c2)
      umount_root;;
    *)
      exit;;
  esac
}

extract_archive(){
  echo "Extracting Archive using tar"
  tar -xzvf $1 -C $2
}

# Invoked by sdcard/write
initos(){
  case $MACHINENAME in
    odroid-c2)
      generaldownload $ODROID_C2_DOWNLOAD_LINK $ODROID_C2_IMAGE_NAME $PARTITION2;;
    *)
      exit;;
  esac
}
