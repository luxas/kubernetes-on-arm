# This command is run by kube-config when doing "kube-config install"
board_post_install(){

    # Enable memory and swap accounting if they doesn't exist already
    
    if [[ -z $(grep "swapaccount=1" /boot/cmdline.txt) ]]; then
        sed -e "s@console=tty1@console=tty1 swapaccount=1@" -i /boot/cmdline.txt
    fi

    if [[ -z $(grep "cgroup_enable=memory" /boot/cmdline.txt) ]]; then
        sed -e "s@console=tty1@console=tty1 cgroup_enable=memory@" -i /boot/cmdline.txt
    fi
         
}