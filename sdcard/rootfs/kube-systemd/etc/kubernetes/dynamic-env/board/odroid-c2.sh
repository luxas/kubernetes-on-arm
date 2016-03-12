# This command is run by kube-config when doing "kube-config install"
board_post_install(){
  # odroid patch, specific to this rootfs. Disable overlay, because linux 3.14 doesn't have overlay support
  sed -e "s@overlay@aufs@" -i $KUBERNETES_CONFIG
}
