#!/bin/bash

# Catch errors
trap 'exit' ERR
set -e

if [[ $K8S_DEBUG == 1 ]]; then
	set -x
fi

KUBERNETES_DIR=/etc/kubernetes
ADDONS_DIR=$KUBERNETES_DIR/addons
KUBERNETES_CONFIG=$KUBERNETES_DIR/k8s.conf
PROJECT_SOURCE=$KUBERNETES_DIR/source
K8S_PREFIX="kubernetesonarm"
GCR_PREFIX="gcr.io/google_containers"

DOCKER_DROPIN_DIR="/usr/lib/systemd/system/docker.service.d"

# The images that are required
REQUIRED_MASTER_IMAGES=("$K8S_PREFIX/flannel $K8S_PREFIX/etcd $K8S_PREFIX/hyperkube $K8S_PREFIX/pause")
REQUIRED_WORKER_IMAGES=("$K8S_PREFIX/flannel $K8S_PREFIX/hyperkube $K8S_PREFIX/pause")
BUILD_ADDON_IMAGES=("$K8S_PREFIX/skydns $K8S_PREFIX/kube2sky $K8S_PREFIX/exechealthz $K8S_PREFIX/registry $K8S_PREFIX/loadbalancer")
REQUIRED_ADDON_IMAGES=("$K8S_PREFIX/skydns $K8S_PREFIX/kube2sky $K8S_PREFIX/exechealthz $K8S_PREFIX/registry $K8S_PREFIX/loadbalancer $GCR_PREFIX/kubernetes-dashboard-arm:v0.1.0")

STATIC_DOCKER_DOWNLOAD="https://github.com/luxas/kubernetes-on-arm/releases/download/v0.6.3/docker-1.10.0"

DEFAULT_TIMEZONE="Europe/Helsinki"
DEFAULT_HOSTNAME="kubepi"

TIMEOUT_FOR_SERVICES=20

LATEST_DOWNLOAD_RELEASE="v0.6.2"

# If the config doesn't exist, create
if [[ ! -f $KUBERNETES_CONFIG ]]; then
	cat > $KUBERNETES_CONFIG <<EOF
K8S_MASTER_IP=127.0.0.1
FLANNEL_SUBNET=10.1.0.0/16
FLANNEL_BACKEND=host-gw
DNS_DOMAIN=cluster.local
DNS_IP=10.0.0.10
EOF
fi

# Always source the config
source $KUBERNETES_CONFIG

usage(){
	cat <<EOF
Welcome to kube-config!

With this utility, you can setup Kubernetes on ARM!

Usage: 
	kube-config install - Installs docker and makes your board ready for kubernetes
	kube-config upgrade - Upgrade current operating system packages to latest version.

	kube-config build-images - Build the Kubernetes images locally
	kube-config build-addons - Build the Kubernetes addon images locally
	kube-config build [image] - Build an image, which is included in the kubernetes-on-arm repository
		- Check for options in $PROJECT_SOURCE/images

	kube-config enable-master - Enable the master services and then kubernetes is ready to use
		- FYI, etcd data will be stored in the /var/lib/kubernetes/etcd directory. Backup that directory if you have important data.
	kube-config enable-worker [master-ip] - Enable the worker services and then kubernetes has a new node
	kube-config enable-addon [addon] ...[addon_n] - Enable one or more addons
		- Currently defined addons
				- dns: Makes all services accessible via DNS
				- registry: Makes a central docker registry
				- sleep: A debug addon. Starts two containers: luxas/alpine and luxas/raspbian.
				- loadbalancer: A loadbalancer that exposes services to the outside world. Experimental.
				- dashboard: A general-purpose Web UI for Kubernetes


	kube-config disable-node - Disable Kubernetes on this node, reverting the enable actions, useful if something went wrong or you just want to stop Kubernetes
	kube-config disable - Synonym to disable-node
	kube-config disable-addon [addon] ...[addon_n] - Disable one or more addons
	
	kube-config delete-data - Clean the /var/lib/kubernetes and /var/lib/kubelet directories, where all master data is stored

	kube-config info - Outputs some version information and info about your board and Kubernetes
	kube-config help - Display this help
EOF
}
#

# Root is required
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  usage
  exit 1
fi

install(){

	# Source the commands, e.g. os_install, os_upgrade, os_post_install, board_post_install
	if [[ -f $KUBERNETES_DIR/dynamic-env/env.conf ]]; then
		source $KUBERNETES_DIR/dynamic-env/env.conf
	fi

	# If some of the options are unset, ask the user
	# This makes it possible to export OS and BOARD before running this command (requires that no env.conf is present)
	if [[ -z $BOARD || -z $OS ]]; then
		read -p "Which board is this running on? Options: [$(ls -l $KUBERNETES_DIR/dynamic-env/board | grep ".sh" | awk '{print $9}'| cut -d. -f1 | sed ':a;N;s/\n/, /;ta')]. " BOARD
		read -p "Which OS do you have? Options: [$(ls -l $KUBERNETES_DIR/dynamic-env/os | grep ".sh" | awk '{print $9}'| cut -d. -f1 | sed ':a;N;s/\n/, /;ta')]. " OS
	fi

	# If some of the options doesn't exist, exit
	if [[ ! -f $KUBERNETES_DIR/dynamic-env/board/$BOARD.sh ]]; then
		echo "Invalid board: $BOARD. That value does not exist. Exiting..."
		exit
	fi
	if [[ ! -f $KUBERNETES_DIR/dynamic-env/os/$OS.sh ]]; then
		echo "Invalid os: $OS. That value does not exist. Exiting..."
		exit
	fi

	# OK, both BOARD and OS are valid. Write the info to the file (even if it was the same as before)
	cat > $KUBERNETES_DIR/dynamic-env/env.conf <<EOF
OS=$OS
BOARD=$BOARD
EOF

	# Source the files
	source $KUBERNETES_DIR/dynamic-env/board/$BOARD.sh
	source $KUBERNETES_DIR/dynamic-env/os/$OS.sh

	# If we have a external command file, use it
	if [[ $(type -t os_install) == "function" ]]; then

		echo "Installing required packages for this OS"
		os_install
	else
		echo "OS not supported. Quitting..."
		exit
	fi

	# Enable the docker and system-docker service
	systemctl enable system-docker docker

	echo "Downloading prebuilt binaries. It is possible to build them manually later."

	# Download latest binaries, now we have them in $PATH
	mkdir -p $PROJECT_SOURCE/images/kubernetesonarm/_bin/latest
	curl -sSL https://github.com/luxas/kubernetes-on-arm/releases/download/$LATEST_DOWNLOAD_RELEASE/binaries.tar.gz | tar -xz -C $KUBERNETES_DIR/binaries

	# Set hostname
	if [[ -z $NEW_HOSTNAME ]]; then
		read -p "What hostname do you want? Defaults to $DEFAULT_HOSTNAME. " hostnameanswer

		hostnamectl set-hostname ${hostnameanswer:-$DEFAULT_HOSTNAME}
	else
		hostnamectl set-hostname $NEW_HOSTNAME
	fi

	# Set timezone
	if [[ -z $TIMEZONE ]]; then
		read -p "Which timezone should be set? Defaults to $DEFAULT_TIMEZONE. " timezoneanswer

		timedatectl set-timezone ${timezoneanswer:-$DEFAULT_TIMEZONE}
	else
		timedatectl set-timezone $TIMEZONE
	fi

	# Has the user explicitely specified it? If not, ask.
	if [[ -z $SWAP ]]; then
		read -p "Do you want to create an 1GB swapfile (required for compiling)? n is default [y/N] " swapanswer
		
		case $swapanswer in
			[yY]*)
				swap;;
		esac
	elif [[ $SWAP == 1 || $SWAP == "y" || $SWAP == "Y" ]]; then
		swap
	fi

	if [[ $(type -t board_post_install) == "function" ]]; then
		echo "Doing some custom work specific to this board"
		board_post_install
	fi

	if [[ $(type -t os_post_install) == "function" ]]; then
		echo "Doing some custom work specific to this OS"
		os_post_install
	fi

	# Reboot?
	if [[ -z $REBOOT ]]; then
		read -p "Do you want to reboot now? A reboot is required for Docker to function. Y is default. [Y/n] " rebootanswer

		case $rebootanswer in
			[nN]*)
				echo "Done.";;
			*)
				reboot;;
		esac
	elif [[ $REBOOT == 1 || $REBOOT == "y" || $REBOOT == "Y" ]]; then
		reboot
	fi
}

upgrade(){
	echo "Upgrading the system"

	# Source the os file and use that upgrade method
	source $KUBERNETES_DIR/dynamic-env/env.conf
	source $KUBERNETES_DIR/dynamic-env/os/$OS.sh
	if [[ $(type -t os_upgrade) == "function" ]]; then
		os_upgrade
	fi
}

swap(){
	echo "Makes an 1GB swapfile, NOTE: it takes up precious SD Card space"

	# Check that the swapfile doesn't already exist
	if [[ ! -f /swapfile ]]; then

		# Make 1GB swap
		dd if=/dev/zero of=/swapfile bs=1M count=1024

		# Enable it with right permissions
		mkswap /swapfile
		chmod 600 /swapfile
		swapon /swapfile

		# And recreate it on every boot
		echo "/swapfile  none  swap  defaults  0  0" >> /etc/fstab
	fi
}

# This is faster than Docker Hub
download_imgs(){
	# Approx. 10 secs faster than doing this with two commands, now ~160 secs
	echo "Downloading Kubernetes docker images from Github"
	curl -sSL https://github.com/luxas/kubernetes-on-arm/releases/download/$LATEST_DOWNLOAD_RELEASE/images.tar.gz | gzip -dc | docker load
	# v0.5.5 curl -sSL https://github.com/luxas/kubernetes-on-arm/releases/download/$LATEST_DOWNLOAD_RELEASE/images.tar.gz | tar -xz -O | docker load
}

### --------------------------------- HELPERS -----------------------------------

# Remove all docker dropins. They are symlinks, so it doesn't matter
dropins-clean(){
	mkdir -p $DOCKER_DROPIN_DIR
	rm -f $DOCKER_DROPIN_DIR/*.conf
}

dropins-enable(){
	systemctl daemon-reload
	systemctl restart docker
}

# Make a symlink from the config file to the dropin location
dropins-enable-overlay(){
	dropins-clean
	ln -s $KUBERNETES_DIR/dropins/docker-overlay.conf $DOCKER_DROPIN_DIR/
	dropins-enable
}

# Make a symlink from the config file to the dropin location
dropins-enable-flannel(){
	dropins-clean
	ln -s $KUBERNETES_DIR/dropins/docker-flannel.conf $DOCKER_DROPIN_DIR/
	dropins-enable
}

require-images(){
	local FAIL=0

	# Loop every image, check if it exists
	for IMAGE in "$@"; do
		if [[ -z $(docker images | grep "$(echo $IMAGE | grep -o "[^:]*" | head -1)") ]]; then

			# If it doesn't exist, try to pull
			echo "Pulling $IMAGE from Docker Hub"
			docker pull $IMAGE
			
			if [[ -z $(docker images | grep "$(echo $IMAGE | grep -o "[^:]*" | head -1)") ]]; then

				echo "Pull failed. Try to pull this image yourself: $IMAGE"
				FAIL=1
			fi
		fi
	done

	if [[ $FAIL == 1 ]]; then
		echo "One or more images failed to pull. Exiting...";
		exit 1
	fi
}

# Load an image to system-docker
load-to-system-docker(){
	# If they doesn't exist, load them from main docker
	if [[ -z $(docker -H unix:///var/run/system-docker.sock images | grep "$1") ]]; then
		echo "Copying $1 to system-docker"
		docker save $1 | docker -H unix:///var/run/system-docker.sock load
	fi
}

get-node-type(){
	local workerstate=$(systemctl is-active k8s-worker)
	local masterstate=$(systemctl is-active k8s-master)
	if [[ $workerstate == "active" ]]; then
		echo "worker";
	elif [[ $masterstate == "active" ]]; then
		echo "master";
	else
		echo "";
	fi
}

# Is kubernetes enabled?
is-active(){
	if [[ $(get-node-type) != "" ]]; then
		echo 1;
	else 
		echo 0;
	fi
}

checkformaster(){
	if [[ $(curl -m 5 -sSLIk http://$1:8080 2>&1 | head -1) == *"OK"* ]]; then
		echo "OK"
	fi
}

# Update variable in k8s.conf
# Example: updateconfig K8S_MASTER_IP [new value]
updateconfig(){
	updateline $KUBERNETES_CONFIG $1 "$1=$2"
}

# Example: updateline path_to_file value_to_search_for replace_that_line_with_this_content
# 
updateline(){
	if [[ -z $(cat $1 | grep "$2") ]]; then
		echo "$3" >> $1
	else
		sed -i "/$2/c\\$3" $1
	fi
}

wait_for_system_docker(){
	# Wait for system-docker to start by "docker ps"-ing every second
	local SYSTEM_DOCKER_SECONDS=0
	while [[ $(docker -H unix:///var/run/system-docker.sock ps 2>&1 1>/dev/null; echo $?) != 0 ]]; do
		((SYSTEM_DOCKER_SECONDS++))
		if [[ ${SYSTEM_DOCKER_SECONDS} == ${TIMEOUT_FOR_SERVICES} ]]; then
		  	echo "system-docker failed to start. Exiting..." 2>&1
		  	exit
		fi
	  sleep 1
	done
}

wait_for_etcd(){
	# Wait for the etcd to answer instead of a timeout. This is faster and more reliable
	local ETCD_SECONDS=0
	while [[ $(curl -fs http://localhost:4001/v2/machines 2>&1 1>/dev/null; echo $?) != 0 ]]; do
		((ETCD_SECONDS++))
		if [[ ${ETCD_SECONDS} == ${TIMEOUT_FOR_SERVICES} ]]; then
		  	echo "etcd failed to start. Exiting..." 2>&1
		  	exit
		fi
	  sleep 1
	done
}

wait_for_flannel(){
	# Wait for the flannel subnet.env file to be created instead of a timeout. This is faster and more reliable
	local FLANNEL_SECONDS=0
	while [[ ! -f /var/lib/kubernetes/flannel/subnet.env ]]; do
		((FLANNEL_SECONDS++))
		if [[ ${FLANNEL_SECONDS} == ${TIMEOUT_FOR_SERVICES} ]]; then
		  	echo "flannel failed to start. Exiting..." 2>&1
		  	exit
		fi
	sleep 1
	done
}

wait_for_docker(){
	# Wait for system-docker to start by "docker ps"-ing every second
	local DOCKER_SECONDS=0
	while [[ $(docker ps 2>&1 1>/dev/null; echo $?) != 0 ]]; do
		((DOCKER_SECONDS++))
		if [[ ${DOCKER_SECONDS} == ${TIMEOUT_FOR_SERVICES} ]]; then
		  	echo "docker failed to start. Exiting..." 2>&1
		  	exit
		fi
	  sleep 1
	done
}

# ----------------------------------------------- MAIN -------------------------------------------

start-master(){

	# Disable some (already running?) services
	echo "Disabling k8s if it is running"
	disable >/dev/null
	sleep 1

	# Require these images to be present
	echo "Checks so all images are present"

	# If hyperkube isn't present, we have probably never pulled the images
	# Then, pull them the first time from Github and fall back on Docker Hub
	if [[ -z $(docker images | grep "$K8S_PREFIX/hyperkube") ]]; then
		download_imgs
	fi

	# Use our normal check-and-pull process
	require-images ${REQUIRED_MASTER_IMAGES[@]}

	# Say that our master is on this board
	updateconfig K8S_MASTER_IP 127.0.0.1

	echo "Transferring images to system-docker, if necessary"
	# Load these master images to system-docker
	load-to-system-docker $K8S_PREFIX/etcd
	load-to-system-docker $K8S_PREFIX/flannel

	# Enable system-docker
	systemctl restart system-docker
	wait_for_system_docker

	# Enable and start our bootstrap services
	systemctl enable etcd
	systemctl start etcd

	wait_for_etcd

	systemctl enable flannel
	systemctl start flannel

	# Wait for etcd and flannel
	wait_for_flannel

	# Create a symlink to the dropin location, so docker will use flannel. Also starts docker
	dropins-enable-flannel

	# Wait for docker to come up
	wait_for_docker

	echo "Starting master components in docker containers"

	# Enable these master services
	systemctl enable k8s-master
	systemctl start k8s-master

	echo "Kubernetes master services enabled"
}

start-worker(){

	# Disable some (already running?) services
	echo "Disabling k8s if it is running"
	disable >/dev/null
	sleep 1

	IP=${1:-$K8S_MASTER_IP}

	echo "Using master ip: $IP"
	updateconfig K8S_MASTER_IP $IP

	# Check if we have a connection
	if [[ $(checkformaster $IP) != "OK" ]]; then
		cat <<EOF
The Kubernetes master was not found.
Exiting...

Command:
kube-config enable-worker [master-ip]
EOF
		exit
	fi

	echo "Checks so all images are present"

	# If hyperkube isn't present, we have probably never pulled the images
	# Then, pull them the first time from Github and fall back on Docker Hub
	# Docker Pull takes 2.2x longer. A normal Github download and install may take 3 mins
	if [[ -z $(docker images | grep "$K8S_PREFIX/hyperkube") ]]; then
		download_imgs
	fi

	# TODO: checks for flannel in main docker, but it may already be in system-docker
	require-images ${REQUIRED_WORKER_IMAGES[@]}

	echo "Transferring images to system-docker, if necessary"
	# Load the images which is necessary to system-docker
	load-to-system-docker $K8S_PREFIX/flannel

	# Enable system-docker
	systemctl restart system-docker
	wait_for_system_docker

	# Enable and start our bootstrap services
	systemctl enable flannel
	systemctl start flannel

	# Wait for flannel
	wait_for_flannel

	# Create a symlink to the dropin location, so docker will use flannel
	dropins-enable-flannel

	# Wait for docker to come up
	wait_for_docker

	echo "Starting worker components in docker containers"

	# Enable these worker services
	systemctl enable k8s-worker
	systemctl start k8s-worker

	echo "Kubernetes worker services enabled"
}

start-addon(){
	if [[ $(is-active) == 1 ]]; then

		# The addon images are required for this operation
		require-images ${REQUIRED_ADDON_IMAGES[@]}

		# The kube-system namespace is required
		NAMESPACE=`eval "kubectl get namespaces | grep kube-system | cat"`

		# Create kube-system if necessary
		if [[ ! "$NAMESPACE" ]]; then
			kubectl create -f $ADDONS_DIR/kube-system.yaml
		fi

		# Source the os file and use that upgrade method
		source $KUBERNETES_DIR/dynamic-env/env.conf
		source $KUBERNETES_DIR/dynamic-env/os/$OS.sh

		for ADDON in $@; do
			if [[ -f $ADDONS_DIR/${ADDON}.yaml ]]; then
				if [[ $(type -t os_addon_$ADDON) == "function" ]]; then

					# Call the os customization handler first
					os_addon_$ADDON
				fi

				# TODO: Maybe fix this better in the future
				if [[ $ADDON == "dns" ]]; then

					# Replace the variables before passing to kubectl
					sed -e "s@DNS_DOMAIN@${DNS_DOMAIN}@;s@DNS_IP@${DNS_IP}@" $ADDONS_DIR/${ADDON}.yaml | kubectl create -f -
				else
					kubectl create -f $ADDONS_DIR/${ADDON}.yaml
				fi

				echo "Started addon: $ADDON"
			else
				echo "This addon doesn't exist: $ADDON"
			fi
		done

	else
		echo "Kubernetes is not running!"
	fi
}

stop-addon(){
	if [[ $(is-active) == 1 ]]; then

		for ADDON in $@; do
			if [[ -d $ADDONS_DIR/${ADDON} ]]; then

				kubectl delete -f $ADDONS_DIR/${ADDON}.yaml

				echo "Stopped addon: $ADDON"
			else
				echo "This addon doesn't exist: $ADDON"
			fi
		done
	else
		echo "Kubernetes is not running!"
	fi
}

disable(){
	systemctl daemon-reload

	systemctl stop flannel etcd k8s-master k8s-worker
	systemctl disable flannel etcd k8s-master k8s-worker
	
	dropins-enable-overlay
}



remove-etcd-datadir(){
	read -p "Do you want to delete all Kubernetes data about this cluster? m(ove) is default, which moves the directories to {,old}. y deletes them and n exits [M/n/y] " removeanswer
	case $removeanswer in
		[nN]*)
			echo "Exiting...";;
		[yY]*)
			umount-kubelet
			rm -rf /var/lib/kubernetes /var/lib/kubelet
			echo "Deleted all Kubernetes data";;
		*)
			umount-kubelet
			rm -rf /var/lib/kubeletold /var/lib/kubernetesold
			mv /var/lib/kubernetes{,old}
			mv /var/lib/kubelet{,old}
			echo "Moved all directories to {,old}";;
	esac
}
umount-kubelet(){
	if [[ ! -z $(mount | grep /var/lib/kubelet | awk '{print $3}') ]]; then
		umount $(mount | grep /var/lib/kubelet | awk '{print $3}')
	fi
}

version(){
	echo "Architecture: $(uname -m)" 
	echo "Kernel: $(uname) $(uname -r | grep -o "[0-9.]*" | grep "[.]")"
	echo "CPU: $(lscpu | grep 'Core(s)' | grep -o "[0-9]*") cores x $(lscpu | grep "CPU max" | grep -o "[0-9]*" | head -1) MHz"

	echo
	echo "Used RAM Memory: $(free -m | grep Mem | awk '{print $3}') MiB"
	echo "RAM Memory: $(free -m | grep Mem | awk '{print $2}') MiB"
	echo
	echo "Used disk space: $(df -h | grep /dev/root | awk '{print $3}')B ($(df | grep /dev/root | awk '{print $3}') KB)"
	echo "Free disk space: $(df -h | grep /dev/root | awk '{print $4}')B ($(df | grep /dev/root | awk '{print $4}') KB)"
	echo

	if [[ -f $KUBERNETES_DIR/SDCard_metadata.conf ]]; then
		source $KUBERNETES_DIR/SDCard_metadata.conf
		D=$SDCARD_BUILD_DATE
		echo "SD Card/deb package was built: $(echo $D | cut -c1-2)-$(echo $D | cut -c3-4)-20$(echo $D | cut -c5-6) $(echo $D | cut -c8-9):$(echo $D | cut -c10-11)"
		echo
		echo "kubernetes-on-arm: "
		echo "Latest commit: $K8S_ON_ARM_COMMIT"
		echo "Version: $K8S_ON_ARM_VERSION"
		echo
	fi

	echo "systemd version: v$(systemctl --version | head -1 | cut -c9-)"
	# Is docker running?
    docker ps 2> /dev/null 1> /dev/null
    if [ "$?" == "0" ]; then

    	DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed -e 's/,$//')
    	echo "docker version: v$DOCKER_VERSION"

    	# if kubectl exists, output k8s server version. If there is no server, output client Version
    	if [[ -f $(which kubectl 2>&1) ]]; then
    		SERVER_K8S=$(kubectl version 2>&1 | grep Server | grep -o "v[0-9.]*" | grep "[0-9]")

    		if [[ ! -z $SERVER_K8S ]]; then
    			echo "kubernetes server version: $SERVER_K8S"
    			echo
    			echo "CPU Time (minutes):"
    			echo "kubelet: $(getcputime kubelet)"

    			# docker 1.7.1 doesn't have docker ps --format. 1.8.0 and newer does
    			# and older versions than 1.7.1 isn't supported
    			if [[ $DOCKER_VERSION != "1.7.1" ]]; then
    				echo "kubelet has been up for: $(docker ps -f "ID=$(docker ps | grep kubelet | awk '{print $1}')" --format "{{.RunningFor}}")"
    			fi


    			if [[ $(get-node-type) == "master" ]]; then
    				echo "apiserver: $(getcputime apiserver)"
    				echo "controller-manager: $(getcputime controller-manager)"
    				echo "scheduler: $(getcputime scheduler)"
    				echo "proxy: $(getcputime proxy)"
    			fi
    		else
    			echo "kubernetes client version: $(kubectl version -c 2>&1 | grep Client | grep -o "v[0-9.]*" | grep "[0-9]")"
    		fi
    	fi
    fi
}

getcputime(){
	echo $(ps aux | grep " $1 " | grep -v grep | grep -v docker | awk '{print $10}')
}

# If nothing is specified, return usage
if [[ $# == 0 ]]; then
        usage
        exit
fi

# Commands available
case $1 in
    'install')
        install;;
    'upgrade')
		upgrade;;
    'build')
		shift
		$PROJECT_SOURCE/images/build.sh $@;;
    'build-images')
        $PROJECT_SOURCE/images/build.sh ${REQUIRED_MASTER_IMAGES[@]};;
    'build-addons')
		$PROJECT_SOURCE/images/build.sh ${BUILD_ADDON_IMAGES[@]};;


    'enable-master')
        start-master;;
    'enable-worker')
        start-worker $2;;
    'enable-addon')
		shift
		start-addon $@;;


	'disable-node')
		disable;;
	'disable')
		disable;;
	'disable-addon')
		shift
		stop-addon $@;;


   	'delete-data')
		remove-etcd-datadir;;
    'info')
		version;;
	'help')
		usage;;
	*) 
		usage;;
esac
