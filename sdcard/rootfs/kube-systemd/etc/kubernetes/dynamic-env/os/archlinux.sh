
os_install(){

    # Catch errors
    set -e

    # Update the system and use pacman to install all the packages
    pacman -Syu --noconfirm

    # Install git and some other required things
    pacman -S git bridge-utils iproute2 --noconfirm --needed

    # Download docker daemon
    curl -sSL $STATIC_DOCKER_DOWNLOAD > /usr/bin/docker
    chmod +x /usr/bin/docker

    # Add the docker group, so the daemon starts
    groupadd -f docker

    # Enable the service files
    mv /usr/lib/systemd/system/docker.service{.backup,}
    mv /usr/lib/systemd/system/docker.socket{.backup,}

    systemctl daemon-reload
}


os_upgrade(){
    pacman -Syu --noconfirm
}

os_post_install(){
    # When on Arch Linux, we've just installed docker, so reboot before use.
    systemctl stop system-docker docker
}

os_addon_dns(){
    # Write the DNS options to the file
    updateline /etc/systemd/network/dns.network "Domains" "Domains=default.svc.$DNS_DOMAIN svc.$DNS_DOMAIN $DNS_DOMAIN"
    updateline /etc/systemd/network/dns.network "DNS" "DNS=$DNS_IP"

    systemctl restart systemd-networkd
}