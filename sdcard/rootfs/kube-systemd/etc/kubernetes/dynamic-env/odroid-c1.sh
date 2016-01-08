# This command is run by kube-config when doing "kube-config install"
post_install(){

	# Customized commands just for odroid-c1
	pacman -S uboot-odroid-c1 --noconfirm
}
