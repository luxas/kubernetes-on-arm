# This command is run by kube-config when doing "kube-config install"
board_post_install(){
  #Disable overlay, because linux 3.14 doesn't have overlay support.
	echo "setting storage driver for docker to devicemapper..."
	sed -i "s/=overlay/=devicemapper/g" $KUBERNETES_CONFIG

	echo "Odroid C2 setup completed"
}
