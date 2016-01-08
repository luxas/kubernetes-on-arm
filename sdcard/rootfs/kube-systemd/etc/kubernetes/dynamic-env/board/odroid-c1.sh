# This command is run by kube-config when doing "kube-config install"
board_post_install(){

	# Odroid-C1 patch, specific to this rootfs. Disable overlay, because linux 3.10.80 doesn't have overlay support
	sed -e "s@-s overlay@@" -i $KUBERNETES_DIR/dropins/docker-flannel.conf
	sed -e "s@-s overlay@@" -i $KUBERNETES_DIR/dropins/docker-overlay.conf
	sed -e "s@-s overlay@@" -i $ROOT/usr/lib/systemd/system/system-docker.service
}
