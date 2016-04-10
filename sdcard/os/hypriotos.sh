#!/bin/bash

RPI_HYPRIOTOS_RELEASE="hypriot-rpi-20151115-132854"
RPI_DOWNLOAD_LINK=http://downloads.hypriot.com/${RPI_HYPRIOTOS_RELEASE}.img.zip
RPI_IMAGE_NAME=${RPI_HYPRIOTOS_RELEASE}.img

. ./os/debian.sh

# Invoked by sdcard/write
initos(){
  case $MACHINENAME in
    rpi|rpi-2|rpi-3)
      generaldownload $RPI_DOWNLOAD_LINK $RPI_IMAGE_NAME $PARTITION2;;
    *)
      exit;;
  esac
}
