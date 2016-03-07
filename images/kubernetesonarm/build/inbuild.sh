#!/bin/bash

# Get version variables
source /version.sh

# Make it run on a RPi 1 too
export GOARM=6

K8S_DIR="$GOPATH/src/k8s.io/kubernetes"
K8S_CONTRIB="$GOPATH/src/k8s.io/contrib"
HEAPSTER_DIR="$GOPATH/src/k8s.io/heapster"
ETCD_DIR="$GOPATH/src/github.com/coreos/etcd"
FLANNEL_DIR="$GOPATH/src/github.com/coreos/flannel"
REGISTRY_DIR="$GOPATH/src/github.com/docker/distribution"
INFLUXDB_DIR="$GOPATH/src/github.com/influxdata/influxdb"
OUTPUT_DIR="/build/bin"

# Make directories
mkdir -p $OUTPUT_DIR \
		$K8S_DIR \
		$K8S_CONTRIB \
		$GOPATH/src/github.com/GoogleCloudPlatform \
		$ETCD_DIR \
		$FLANNEL_DIR \
		$REGISTRY_DIR \
		$HEAPSTER_DIR \
		$INFLUXDB_DIR

# Symlink $GOPATH/src/k8s.io/kubernetes and the old $GOPATH/src/github.com/GoogleCloudPlatform/kubernetes
ln -s $GOPATH/src/k8s.io/kubernetes $GOPATH/src/github.com/GoogleCloudPlatform/kubernetes

echo "Environment set up"

## ETCD ##
# Download a gzipped archive and extract
curl -sSL https://github.com/coreos/etcd/archive/$ETCD_VERSION.tar.gz | tar -C $ETCD_DIR -xz --strip-components=1
cd $ETCD_DIR

# Build etcd
./build

# Copy over the binaries
cp bin/* $OUTPUT_DIR
echo "etcd built"

## FLANNEL ##
# Download a gzipped archive and extract
curl -sSL https://github.com/coreos/flannel/archive/$FLANNEL_VERSION.tar.gz | tar -C $FLANNEL_DIR -xz --strip-components=1
cd $FLANNEL_DIR

# Build statically
sed -e "s@go build -o \${GOBIN}/flanneld \${REPO_PATH}@go build -o \${GOBIN}/flanneld -ldflags \"-extldflags '-static'\" \${REPO_PATH}@" -i build

# And build statically
./build

# Copy over the binaries
cp bin/* $OUTPUT_DIR
echo "flannel built"

### KUBERNETES ###
# Download a gzipped archive and extract
curl -sSL https://github.com/kubernetes/kubernetes/archive/$K8S_VERSION.tar.gz | tar -C $K8S_DIR -xz --strip-components=1
cd $K8S_DIR

## Patches for building Kubernetes
if [[ $K8S_VERSION == "v1.1"* ]]; then
	echo "Building a v1.1.x branch of kubernetes. Patching."

	# libcontainer ARM issue. That file is by default built only on amd64
	mv Godeps/_workspace/src/github.com/docker/libcontainer/seccomp/jump{_amd64,}.go
	sed -e "s@,amd64@@" -i Godeps/_workspace/src/github.com/docker/libcontainer/seccomp/jump.go

	# Patch the nsenter writer, this is fixed on master: #16969
	curl -sSL https://raw.githubusercontent.com/kubernetes/kubernetes/8c1d820435670e410f8fd54401906c3d387c2098/pkg/util/io/writer.go > pkg/util/io/writer.go

	# Build kubectl statically
	export KUBE_STATIC_OVERRIDES="kubectl"

	# Build only these two kubernetes binaries
	./hack/build-go.sh \
		cmd/hyperkube \
		cmd/kubectl

	# Copy over the binaries
	cp _output/local/bin/linux/arm/* $OUTPUT_DIR

elif [[ $K8S_VERSION == "v1.2"* ]]; then
	echo "Building a v1.2.x branch of kubernetes. Downloading official binaries."
	curl -sSL https://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/linux/arm/hyperkube > $OUTPUT_DIR/hyperkube
	curl -sSL https://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/linux/arm/kubectl > $OUTPUT_DIR/kubectl
	chmod +x $OUTPUT_DIR/hyperkube $OUTPUT_DIR/kubectl
else
	echo "Building an old branch of kubernetes. Not supported."
	exit
fi


echo "kubernetes built"

## PAUSE ##
cd $K8S_DIR/build/pause

# Build the binary
./prepare.sh

# Copy over the binaries
cp pause $OUTPUT_DIR
echo "pause built"

## KUBE2SKY ##
cd $K8S_DIR/cluster/addons/dns/kube2sky

if [[ $K8S_VERSION == "v1.1"* ]]; then

	# Build for arm, fixed on master, #18669
	sed -e "s@GOARCH=amd64@GOARCH=arm@" -i Makefile
fi

# Build the binary
make kube2sky

# Include in build result
cp kube2sky $OUTPUT_DIR
echo "kube2sky built"

## SKYDNS ##
# Compile the binary statically, requires mercurial
#go get github.com/skynetservices/skydns
CGO_ENABLED=0 go get -a -installsuffix cgo --ldflags '-w' github.com/skynetservices/skydns

# And copy over it
cp $GOPATH/bin/skydns $OUTPUT_DIR
echo "skydns built"

## IMAGE REGISTRY ##
# Download a gzipped archive and extract
curl -sSL https://github.com/docker/distribution/archive/$REGISTRY_VERSION.tar.gz | tar -xz -C $REGISTRY_DIR --strip-components=1
cd $REGISTRY_DIR/cmd/registry

GOPATH=$REGISTRY_DIR/Godeps/_workspace:$GOPATH go build

# include rados, oss and gce storage drivers (optional)
# apt-get install -y librados-dev apache2-utils
# go build --tags include_rados include_oss include_gcs -v

# And compile. This gopath hack may also be resolved by using godep
# this is much slower than above
#GOPATH=$REGISTRY_DIR/Godeps/_workspace:$GOPATH make -C $REGISTRY_DIR $REGISTRY_DIR/bin/registry 
# go get github.com/docker/distribution/cmd/registry

# Copy the binary
cp registry $OUTPUT_DIR
echo "registry built"

## K8S CONTRIB ##
curl -sSL https://github.com/kubernetes/contrib/archive/master.tar.gz | tar -xz -C $K8S_CONTRIB --strip-components=1

## LOAD BALANCER ##
cd $K8S_CONTRIB/service-loadbalancer

# Build the binary
make server

# Copy the binary
cp service_loadbalancer $OUTPUT_DIR
echo "service_loadbalancer built"

## EXECHEALTHZ ##
cd $K8S_CONTRIB/exec-healthz

# Build the binary
make server

# Copy over the binary
cp exechealthz $OUTPUT_DIR
echo "exechealthz built"

## HEAPSTER ##
curl -sSL https://github.com/kubernetes/heapster/archive/$HEAPSTER_VERSION.tar.gz | tar -C $HEAPSTER_DIR -xz --strip-components=1
cd $HEAPSTER_DIR

CGO_ENABLED=0 godep go build -a -installsuffix cgo ./... 
CGO_ENABLED=0 godep go build -a -installsuffix cgo

cp heapster $OUTPUT_DIR
echo "heapster built"


## INFLUXDB ##

curl -sSL https://github.com/influxdata/influxdb/archive/$INFLUXDB_VERSION.tar.gz | tar -C $INFLUXDB_DIR -xz --strip-components=1
cd $INFLUXDB_DIR

go get github.com/sparrc/gdm

gdm restore -v

CGO_ENABLED=0 go build -a --installsuffix cgo --ldflags="-s" -o influxd ./cmd/influxd

cp influxd $OUTPUT_DIR
echo "influxdb built"

## GRAFANA ##

# go get github.com/grafana/grafana
# cd $GOPATH/src/github.com/grafana/grafana
# go run build.go setup
# godep restore
# go run build.go build

## SCALE DEMO ##
#cd $K8S_CONTRIB/scale-demo/aggregator

#make aggregator

#cp aggregator /build/bin

#cd $K8S_CONTRIB/scale-demo/vegeta

# Build the binary
#CGO_ENABLED=0 GOOS=linux godep go build -a -installsuffix cgo -ldflags '-w' -o loader
# make loader

#cp loader /build/bin