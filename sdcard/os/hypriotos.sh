

RPI_HYPRIOTOS_RELEASE="hypriot-rpi-20151115-132854"
RPI_DOWNLOAD_LINK=http://downloads.hypriot.com/${RPI_HYPRIOTOS_RELEASE}.img.zip

# Wait until these images are ready with a newer kernel and more free space partitioned
ODROID_C1_HYPRIOTOS_VERSION="v0.2.1"
ODROID_C1_HYPRIOTOS_RELEASE="sd-card-odroid-c1-${ODROID_C1_HYPRIOTOS_VERSION}"
ODROID_C1_DOWNLOAD_LINK=https://github.com/hypriot/image-builder-odroid-c1/releases/download/${ODROID_C1_HYPRIOTOS_VERSION}/${ODROID_C1_HYPRIOTOS_RELEASE}.img.zip

# Add odroid-c1 support:
# 
# initos(){
#+		odroid-c1)
#+			generaldownload $ODROID_C1_DOWNLOAD_LINK $ODROID_C1_HYPRIOTOS_RELEASE $PARTITION1;;
# }

# cleanup(){
#+		rpi|rpi-2|odroid-c1)
#-		rpi|rpi-2)
# }


# First invoked by sdcard/write
mountpartitions(){
	# Partition the sd card
	# There's nothing to do here, because all this is made with dd
	echo "No extra partition work has to be done. Continuing..."
}

# Invoked by sdcard/write
initos(){
	case $MACHINENAME in
		rpi|rpi-2|rpi-3)
			generaldownload $RPI_DOWNLOAD_LINK $RPI_HYPRIOTOS_RELEASE $PARTITION2;;
		*)
			exit;;
	esac
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


# Takes an URL (.img.zip file) to download an the name of the downloaded file. Assumes that the extracted and the downloaded file has the same names except for the extension
generaldownload(){

	# Install unzip and partprobe if not present
	require unzip unzip
	require partprobe partprobe

	# We can't write this .img file to /tmp because /tmp has a limit of 462MB
	DLDIR=/etc/tmp/downloadhypriot
	DL_LINK=$1
	RELEASE=$2
	ROOT_PARTITION=$3
	ZIPFILE=$DLDIR/${RELEASE}.img.zip

	# Ensure this page is present
	mkdir -p $DLDIR

	# Do not overwrite the .img.zip file if that release already exists
	if [[ ! -f $ZIPFILE ]]; then
		curl -sSL $DL_LINK > $ZIPFILE
	fi

	# Do not overwrite the .img file if that release already exists
	if [[ ! -f $DLDIR/${RELEASE}.img ]]; then
		unzip $ZIPFILE -d $DLDIR
	fi

	dd if=$DLDIR/${RELEASE}.img of=$SDCARD bs=4M

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
