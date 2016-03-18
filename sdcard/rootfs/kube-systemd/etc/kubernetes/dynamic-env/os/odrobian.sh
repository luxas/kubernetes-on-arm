DOCKER_HYPRIOT_DEB="docker-hypriot_1.10.3-1_armhf.deb"
DOCKER_HYPRIOT_DEB_FILE="/tmp/"$DOCKER_HYPRIOT_DEB

os_install(){

	os_upgrade

	if [[ ! -f $(which curl 2>&1) ]]; then
		echo "Installing curl ..."
		apt-get install curl -y
	fi

	if [[ ! -f $(which docker 2>&1) ]]; then
		echo "Installing docker ..."
		install_docker
	fi

	if [[ ! -f $(which sudo 2>&1) ]]; then
		echo "Installing sudo ..."
		apt-get install sudo -y
	fi

	echo "Installing dbus and avahi-daemon ..."
	apt-get install -y dbus avahi-daemon
}

install_docker(){
	apt-get install lxc lvm2 cgroup-tools apparmor bridge-utils -y
	wget -O $DOCKER_HYPRIOT_DEB_FILE https://downloads.hypriot.com/$DOCKER_HYPRIOT_DEB
	dpkg -i $DOCKER_HYPRIOT_DEB_FILE
	systemctl stop docker
	sed -i "s/=overlay/=devicemapper/g" /etc/default/docker
	rm -Rf /var/lib/docker/*
	systemctl restart docker
}


os_upgrade(){
	echo "Upgrading packages ..."
	apt-get update -y && apt-get dist-upgrade -y && apt-get upgrade -y
}

os_post_install(){
	echo "Post install ..."
	DEFAULT_HOSTNAME="odroid32"
	NEW_HOSTNAME=$(hostnamectl | grep hostname | awk '{print $3}')
	sed -i "s/$DEFAULT_HOSTNAME/$NEW_HOSTNAME/g" /etc/hosts
	rm $DOCKER_HYPRIOT_DEB_FILE
}

os_addon_dns(){
	# Write the DNS options to the file
	updateline /etc/dhcp/dhclient.conf "prepend domain-search" "prepend domain-search \"default.svc.$DNS_DOMAIN\",\"svc.$DNS_DOMAIN\",\"$DNS_DOMAIN\";"
	updateline /etc/dhcp/dhclient.conf "prepend domain-name-servers" "prepend domain-name-servers $DNS_IP;"

	# Flush changes
	systemctl restart networking
}
