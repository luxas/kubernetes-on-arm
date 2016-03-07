# Images build speed and size

These images are built on a Raspberry Pi 2.

## 0.6.5

55 files changed, 602 insertions(+), 659 deletions(-)

## 0.6.3

66 files changed, 865 insertions(+), 1153 deletions(-)

## 0.6.2

74 files changed, 1615 insertions(+), 611 deletions(-)

  - luxas/raspbian: 331 s
  - luxas/alpine: 55 s
  - luxas/go: 1261 s

  - kubernetesonarm/build: 1636 s
  - kubernetesonarm/flannel: 155 s
  - kubernetesonarm/etcd: 33 s 
  - kubernetesonarm/hyperkube: 287 s
  - kubernetesonarm/pause: 4 s 
  - kubernetesonarm/exechealthz: 14 s
  - kubernetesonarm/skydns: 6 s
  - kubernetesonarm/kube2sky: 11 s
  - kubernetesonarm/registry: 112 s

```bash
$ ls -lh
total 173M
-rwxr-xr-x 1 root root  17M Dec 20 20:34 aggregator
-rwxr-xr-x 1 root root  11M Dec 20 20:16 etcd
-rwxr-xr-x 1 root root 9.8M Dec 20 20:16 etcdctl
-rwxr-xr-x 1 root root 3.6M Dec 20 20:31 exechealthz
-rwxr-xr-x 1 root root  13M Dec 20 20:17 flanneld
-rwxr-xr-x 1 root root  45M Dec 20 20:24 hyperkube
-rwxr-xr-x 1 root root  14M Dec 20 20:26 kube2sky
-rwxr-xr-x 1 root root  18M Dec 20 20:24 kubectl
-rwxr-xr-x 1 root root 4.2M Dec 20 20:34 loader
-rwxr-xr-x 1 root root 222K Dec 20 20:24 pause
-rwxr-xr-x 1 root root  13M Dec 20 20:29 registry
-rwxr-xr-x 1 root root  17M Dec 20 20:31 service_loadbalancer
-rwxr-xr-x 1 root root  11M Dec 20 20:28 skydns
-rwxr-xr-x 1 root root  719 Dec 20 20:39 version.sh
```

To build `hyperkube` and `kubectl`: ~6 mins

Total time: 3905 s, 65 min 5 sec

## 0.6.0

63 files changed, 1916 insertions(+), 407 deletions(-)

  - luxas/raspbian: 273 s
  - luxas/alpine: 47 s
  - luxas/go: 1042 s

  - kubernetesonarm/build: 1248 s
  - kubernetesonarm/flannel: 119 s
  - kubernetesonarm/etcd: 14 s 
  - kubernetesonarm/hyperkube: 242 s
  - kubernetesonarm/pause: 1 s 
  - kubernetesonarm/exechealthz: 5 s
  - kubernetesonarm/skydns: 4 s
  - kubernetesonarm/kube2sky: 5 s
  - kubernetesonarm/registry: 157 s

```bash
$ ls -lh
total 134M
-rwxr-xr-x 1 root root  11M Nov 28 17:37 etcd
-rwxr-xr-x 1 root root 9.1M Nov 28 17:37 etcdctl
-rwxr-xr-x 1 root root 3.6M Nov 28 17:50 exechealthz
-rwxr-xr-x 1 root root  13M Nov 28 17:38 flanneld
-rwxr-xr-x 1 root root  45M Nov 28 17:44 hyperkube
-rwxr-xr-x 1 root root  14M Nov 28 17:46 kube2sky
-rwxr-xr-x 1 root root  18M Nov 28 17:44 kubectl
-rwxr-xr-x 1 root root 222K Nov 28 17:45 pause
-rwxr-xr-x 1 root root  13M Nov 28 17:49 registry
-rwxr-xr-x 1 root root  10M Nov 28 17:48 skydns
-rwxr-xr-x 1 root root  717 Nov 28 17:54 version.sh

```


Total time: 3157 s, 52 min 37 sec

## 0.5.5
  - luxas/raspbian: 254 s
  - luxas/alpine: 41 s
  - luxas/go: 1135 s

  - kubernetesonarm/build: 880 s
  - kubernetesonarm/flannel: 109 s
  - kubernetesonarm/etcd: 10 s 
  - kubernetesonarm/hyperkube: 161 s
  - kubernetesonarm/pause: 1 s 
  - kubernetesonarm/exechealthz: 5 s
  - kubernetesonarm/skydns: 2 s
  - kubernetesonarm/kube2sky: 3 s
  - kubernetesonarm/registry: 168 s

```bash
$ ls -lh
total 109M
-rwxr-xr-x 1 root root 5.1M Oct 14 23:44 etcd
-rwxr-xr-x 1 root root 4.7M Oct 14 23:44 etcdctl
-rwxr-xr-x 1 root root 3.6M Oct 14 23:44 exechealthz
-rwxr-xr-x 1 root root 9.0M Oct 14 23:44 flanneld
-rwxr-xr-x 1 root root  38M Oct 14 23:44 hyperkube
-rwxr-xr-x 1 root root  13M Oct 14 23:44 kube2sky
-rwxr-xr-x 1 root root  15M Oct 14 23:44 kubectl
-rwxr-xr-x 1 root root 222K Oct 14 23:44 pause
-rwxr-xr-x 1 root root  13M Oct 14 23:44 registry
-rwxr-xr-x 1 root root 9.5M Oct 14 23:44 skydns
-rwxr-xr-x 1 root root  482 Oct 14 23:44 version.sh
```

Total time for kube-config: 2769 s, 46 min 9 sec

## 0.5.0
 - luxas/raspbian: 254 s
 - luxas/alpine: 36 s
 - luxas/go: 1140 s

 - kubernetesonarm/build: 857 s
 - kubernetesonarm/flannel: 115 s
 - kubernetesonarm/etcd: 8 s 
 - kubernetesonarm/hyperkube: 163 s
 - kubernetesonarm/pause: 1 s 
 - kubernetesonarm/exechealthz: 4 s
 - kubernetesonarm/skydns: 4 s
 - kubernetesonarm/kube2sky: 5 s

 Total time for kube-config: 2574 s, 42 min 54 sec


## 0.4.9
 - luxas/raspbian: 241 s
 - luxas/alpine: 43 s
 - luxas/go: 1151 s

 - k8s/build: 891 s
 - k8s/hyperkube: 183 s
 - k8s/etcd: 13 s
 - k8s/flannel: 107 s
 - k8s/pause: 1 s
 - k8s/exechealthz: 3 s
 - k8s/skydns: 3 s 
 - k8s/kube2sky: 4 s 

 - luxas/nginx: 10 s

 To get all k8s up and running from scratch: 2640 s, 44 min


## 0.4.1
 - luxas/raspbian: 224 s
 - luxas/alpine: 39 s
 - luxas/archlinux: 318 s

 - luxas/go: 960 s
 - luxas/nodejs: 10 s
 - luxas/nginx: 12 s
 - luxas/registry: 220 s

 - k8s/build: 699 s
 - k8s/etcd: 17 s
 - k8s/hyperkube: 142 s
 - k8s/flannel: 111 s
 - k8s/pause: 2 s

 To get k8s up and running from scratch: 2194 s, 36m 34s
 All images time: 2754 s, 45m 54s



## 0.4.0

- luxas/raspbian: 237 s
- luxas/alpine: 38 s
- luxas/go: 1210 s
- luxas/nodejs: 16 s
- luxas/registry: 350 s


- k8s/build: 2208 s
- k8s/hyperkube: 227 s
- k8s/etcd: 13 s
- k8s/flannel: 126 s
- k8s/pause: 1 s

To get k8s up and running from scratch: 4060 s, 1h 7m 40s