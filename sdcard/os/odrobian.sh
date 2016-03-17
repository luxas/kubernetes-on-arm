# 32-bit/64-bit Odrobian image
ODROBIAN_C2_RELEASE="odrobian-2.0-server-s905~crashoverride"
ODROBIAN_C2_DOWNLOAD_LINK=http://oph.mdrjr.net/odrobian/images/s905/${ODROBIAN_C2_RELEASE}.img.xz

mountpartitions(){
	# Partition the sd card
	# There's nothing to do here, because all this is made with dd
	echo "No extra partition work has to be done. Continuing..."
}

# Invoked by sdcard/write
initos(){
	case $MACHINENAME in
		odroid-c2)
			generaldownload $ODROBIAN_C2_DOWNLOAD_LINK $ODROBIAN_C2_RELEASE $PARTITION2;;
		*)
			exit;;
	esac
}

# Invoked by sdcard/write
cleanup(){
	case $MACHINENAME in
		odroid-c2)
			umount_root;;
		*)
			exit;;
	esac
}

# Takes an URL (.img.zip file) to download an the name of the downloaded file. Assumes that the extracted and the downloaded file has the same names except for the extension
generaldownload(){
  echo "Downloding odrobian"
	# Install unzip if not present
	require unxz

	DLDIR=/tmp/downloadodrobian
	DL_LINK=$1
	RELEASE=$2
	ROOT_PARTITION=$3
  IMGFILE=$DLDIR/${RELEASE}.img.xz
	XZFILE=$IMGFILE.xz

	# Ensure this page is present
	mkdir -p $DLDIR

	# Do not overwrite the .img.xz file if that release already exists
	if [[ ! -f $XZFILE ]]; then
		curl -sSL $DL_LINK > $XZFILE
	fi

	# Do not overwrite the .img file if that release already exists
	if [[ ! -f $DLDIR/${RELEASE}.img ]]; then
		unxz $XZFILE
	fi

	dd if=$IMGFILE of=$SDCARD bs=4M

	sync

	mount $ROOT_PARTITION $ROOT
}

umount_root(){
	umount $ROOT
}
