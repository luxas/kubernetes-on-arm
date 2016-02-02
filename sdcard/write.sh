#!/bin/bash

########################## HELPER ##############################

# Install a package 
require()
{
	BINARY=$1
	PACKAGE=$2

	# If the $BINARY path -e(xists)
	if [[ ! -e $(which $BINARY 2>&1) ]]; then
		
		if [[ -e $(which pacman 2>&1) ]]; then # Is pacman present?
			pacman -S $PACKAGE --noconfirm
			
		elif [[ -e $(which apt-get 2>&1) ]]; then # Is apt-get present?
			apt-get install -y $PACKAGE
		else
			echo "The required package $PACKAGE with the binary $BINARY isn't present now. Install it."
			exit 1
		fi
	fi
}

########################## USAGE ##############################

usage(){
	cat <<EOF
Welcome to the write to sd card process!
This script will allow you to:
	- Write an os to a SD Card
	- Customize for a specific type of board
	- Insert files and configuration via a a prepopulated rootfs, so your os works out-of-the-box!

Required arguments:

sdcard/write.sh [disc or sd card] [boot] [os]

Optional argument:

sdcard/write.sh [disc or sd card] [boot] [os] [rootfs]

Explanation:
	disc - The SD Card place, often /dev/sdb or something. Run 'fdisk -l' to see which letter your sd card has.
	boot - The type of board you have
		- Currently supported:
			- rpi - Raspberry Pi A, A+, B, B+, ZERO
			- rpi-2 - Raspberry Pi 2 Model B
			- parallella - Adepteva Parallella board. Note: Awfully slow. Do not use as-is. But you're welcome to hack and improve it. Should have a newer kernel
			- cubietruck - Cubietruck
			- bananapro - Banana Pro
			- odroid-c1 - Hardkernel Odroid-C1
	os - The operating system which should be downloaded and installed.
		- Currently supported:
			- archlinux - Arch Linux ARM
			- hypriotos - HypriotOS
	rootfs - Prepopulated rootfs with scripts and such.
		- Currently supported: 
			- kube-systemd - Kubernetes scripts prepopulated (optional)

Example:
sdcard/write.sh /dev/sdb rpi-2 archlinux kube-systemd
EOF
}


# Catch errors
trap 'exit' ERR

# cd to current dir ~/sdcard
cd "$( dirname "${BASH_SOURCE[0]}" )"

########################## SECURITY CHECKS ##############################

# Root is required
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  usage
  exit 1
fi

# At least three arguments should be present
if [[ "$#" < 3 ]]; then
	echo "You must specify at least three arguments."
	usage
	exit 1
fi

# Require fdisk to be installed
require fdisk fdisk

# Check that it really is a disk
if [[ -z $(fdisk -l | grep "$1") ]]; then
	echo "The disc $1 doesn't exist. Check with 'fdisk -l'"
	exit 1
fi

########################## OPTIONS ##############################

# /dev/sdb, /dev/sdb1, /dev/sdb2
SDCARD=$1

# Special case. the mmcblk0 disc's partitions are named p1 and p2 instead of 1 and 2 
if [[ $SDCARD == "/dev/mmcblk"* ]]; then
	PARTITION1=${1}p1
	PARTITION2=${1}p2	
else
	PARTITION1=${1}1
	PARTITION2=${1}2
fi

# A tmp dir to store things in, a boot partition and the root filesystem
TMPDIR=$(mktemp -d /tmp/writesdcard.XXXXXXXX)
BOOT=$TMPDIR/boot
ROOT=$TMPDIR/root
PROJROOT=./..
LOGFILE=/tmp/kubernetes-on-arm.log

MACHINENAME=$2
OSNAME=$3
ROOTFSNAME=$4


if [[ -z $QUIET || $QUIET == 0 ]]; then

	# Security check
	read -p "You are going to lose all your data on $1. Continue? (Y is default) [Y/n]" answer

	case $answer in 
	  	[nN]*) 
			echo "Quitting..."
			rm -r $TMPDIR
	      	exit 1;;		
	esac

	# OK to continue
	echo "OK. Continuing..."
fi

########################## SOURCE FILES ##############################

# Make some temp directories
mkdir -p $ROOT $BOOT

# Ensure the OS exists	
if [[ ! -f os/$OSNAME.sh ]]; then
	echo "os/$OSNAME.sh not found. That file is required. Exiting..."
	rm -r $TMPDIR
	exit 1
fi

# Rewrite for compability
if [[ $ROOTFSNAME == "kube-archlinux" ]]; then
	echo "DEPRECATED: kube-archlinux is a deprecated name. Use kube-systemd. Continuing with kube-systemd anyway..."
	ROOTFSNAME="kube-systemd"
fi

# Ensure the rootfs exists	
if [[ ! -d rootfs/$ROOTFSNAME ]]; then
	echo "rootfs/$ROOTFSNAME not found. That rootfs doesn't exist. Exiting..."
	rm -r $TMPDIR
	exit 1
fi

# Source machine and os
source os/$OSNAME.sh

# OS must provide:
# mountpartitions()
# initos()
# cleanup()

# Mount them
mountpartitions

echo "Partitions mounted"

echo "Downloading OS and writing to SD Card"

# Download a tar file and extract it, requires $MACHINENAME
initos

echo "OS written to SD Card"

# Populate rootfs
if [[ -d rootfs/$ROOTFSNAME ]]; then

	# Prepopulate the rootfs
	cp -r rootfs/$ROOTFSNAME/* $ROOT

	# If we've a dynamic rootfs, invoke it
	if [[ -f rootfs/$ROOTFSNAME/dynamic-rootfs.sh ]]; then
		
		# Source the dynamic rootfs script
		source rootfs/$ROOTFSNAME/dynamic-rootfs.sh

		# And invoke the function
		rootfs
	fi
fi

# Clean up
# Unmount boot and root, call the os file
cleanup

# Remove the temp filesystem
rm -r $TMPDIR

echo "Finished writing your SD Card."