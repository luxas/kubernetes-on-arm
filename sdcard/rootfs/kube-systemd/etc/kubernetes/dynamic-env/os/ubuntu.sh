os_install(){

  # Update the system and use pacman to install all the packages
  # The two commands may be combined, but I leave it as is for now.
  os_upgrade

  # If brctl isn't installed, install it
  if [[ ! -f $(which brctl 2>&1) ]]; then
    apt-get install bridge-utils -y
  fi
  # If curl isn't installed, install it
  if [[ ! -f $(which curl 2>&1) ]]; then
    apt-get install curl -y
  fi
  apt-get install aufs-tools
}


os_upgrade(){
  echo "Upgrading packages..."
  apt-get update -y && apt-get upgrade -y
}

os_post_install(){
  newhostname=$(hostnamectl | grep hostname | awk '{print $3}')
}

os_addon_dns(){
  # Write the DNS options to the file
  updateline /etc/dhcp/dhclient.conf "prepend domain-search" "prepend domain-search \"default.svc.$DNS_DOMAIN\",\"svc.$DNS_DOMAIN\",\"$DNS_DOMAIN\";"
  updateline /etc/dhcp/dhclient.conf "prepend domain-name-servers" "prepend domain-name-servers $DNS_IP;"

  # Flush changes
  systemctl restart networking
}
