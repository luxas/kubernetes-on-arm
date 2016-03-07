# Specify which versions the binaries should have

# Two options, a branch like 'master' or a version tag e. g. 'v1.0.1'
# Todo: maybe include the download paths here also

## GITHUB PROJECTS ##
# These projects are downloaded from "github.com/user/repo/archive/$VERSION.tar.gz"
K8S_VERSION='v1.2.0-beta.0'
ETCD_VERSION='v2.2.5'
FLANNEL_VERSION='v0.5.5'
REGISTRY_VERSION='v2.3.0'
HEAPSTER_VERSION='v0.20.0-alpha11'

## OTHER PROJECTS ##
# For the moment, go1.4.3 is a better choice than go1.5.1
# Because building with go1.5.1 is 2-4x slower than 1.4.3
# And there's no big difference in the result
# TODO: use prebuilt official go1.6
GO_VERSION='1.4.3'

# Enable go1.5.1 by commenting above and uncommenting here
# GO_BOOTSTRAP_VERSION='go1.4.3'
# GO_VERSION='go1.5.2'