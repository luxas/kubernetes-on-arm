
RANCHEROS_RELEASE="rancheros-rpi2-20160221"
RANCHEROS_DOWNLOAD_LINK=http://downloads.hypriot.com/${RANCHEROS_RELEASE}.zip

# First invoked by sdcard/write
mountpartitions(){
	# Partition the sd card
	# There's nothing to do here, because all this is made with dd
	echo "No extra partition work has to be done. Continuing..."
}

# Invoked by sdcard/write
initos(){
	case $MACHINENAME in
		rpi-2|rpi-3)
			generaldownload $RANCHEROS_DOWNLOAD_LINK $RANCHEROS_RELEASE $PARTITION2;;
		*)
			exit;;
	esac
}

# Invoked by sdcard/write
cleanup(){
	case $MACHINENAME in
		rpi-2|rpi-3)
			umount_root;;
		*)
			exit;;
	esac
}


# Takes an URL (.zip file) to download an the name of the downloaded file. Assumes that the extracted and the downloaded file has the same names except for the extension
generaldownload(){

	# Install unzip if not present
	require unzip unzip

	# We can't write this .img file to /tmp because /tmp has a limit of 462MB
	DLDIR=/etc/tmp/downloadrancher
	DL_LINK=$1
	RELEASE=$2
	ROOT_PARTITION=$3
	ZIPFILE=$DLDIR/${RELEASE}.zip

	# Ensure this page is present
	mkdir -p $DLDIR

	# Do not overwrite the .zip file if that release already exists
	if [[ ! -f $ZIPFILE ]]; then
		curl -sSL $DL_LINK > $ZIPFILE
	fi

	# Do not overwrite the .img file if that release already exists
	if [[ ! -f $DLDIR/build/run.img ]]; then
		unzip $ZIPFILE -d $DLDIR
	fi

	dd if=$DLDIR/build/run.img of=$SDCARD bs=4M

	sync

	mount $ROOT_PARTITION $ROOT
}

umount_root(){
	umount $ROOT
}