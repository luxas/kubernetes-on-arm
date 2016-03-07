### Roadmap for Kubernetes on ARM

Just some notes about what I probably will include in this project

#### Future improvements
 - Upgrade to Kubernetes v1.2.0, when it's released. Also bump to `registry` v2.3.0 and `etcd` v2.3.0 when available
 - Run `kube-proxy` as a DaemonSet on worker, at least not supported before the v1.2.0 release of Kubernetes
 - Investigate if `heapster` is lightwight enough to run on ARM
 - Is Scaleway supported now with the `.deb` package? Find out
 - Ability to auto-upgrade the kube-systemd package
 - Investigate what happens if the master is up for one or two days => scalability tests
 - Change to native docker volume `rshared` mounting instead of `--containerized` when it's stable
 - Maybe add support for Odroid C1, C2, XU4, Pine64, Nvidia ShieldTV. The problem is old kernels.
 - Add a stable `.tar.gz` deployment besides the `.deb` deployment
 - Maybe build `flannel` statically to minimize image size
 - Use `host-gw` as the backend for the `flannel` overlay network
 - Support RancherOS on ARM and make a rootfs
 - Add a catalog with prebuilt apps that integrate well with Kubernetes and may be used as demos
 - Use `iptables` proxying when it's working