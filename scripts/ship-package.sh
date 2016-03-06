#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )"/..

PACKAGE=${PACKAGE:-1}
BUILD=${BUILD:-0}

# Move to an USB or a folder
if [[ $# == 1 ]]; then

    source scripts/common.sh

    # First build binaries/images
    if [[ $BUILD == 1 ]]; then

        echo "Building binaries and images..."
        time images/build.sh ${IMAGES[@]}
    fi

    # Then package binaries
    if [[ $PACKAGE == 1 ]]; then

		echo "Packaging artifacts..."
        scripts/package.sh
    fi

    BUILDDIR=release/latest
    OUTDIR="$(parse-path-or-disc $1)/kubernetesonarm_$(date +%d%m%y_%H%M)"

    mkdir -p $OUTDIR

    echo "Copying files..."
    cp $BUILDDIR/* $OUTDIR

    cleanup-path-or-disc
else
	cat <<EOF
Packages Kubernetes images, binaries, the .deb file and kubectl to a target

Usage:
PACKAGE=(1=default|0) BUILD=(0=default|1) scripts/ship-package.sh [disc or partition or absolute path]

Examples:
PACKAGE=0 scripts/ship-package.sh /dev/sda2
PACKAGE=1 scripts/ship-package.sh /dev/sda [/dev/sda1 automatically chosen]
scripts/ship-package.sh /etc/k8s-artifacts

Variables:
BUILD: If the images should be built.
PACKAGE: If the script should package binaries and images into .tar.gz archives. If not, use already-made packages in release/latest
PACKAGE_BRANCH: The ref that git should checkout when building the package. Defaults to master
PACKAGE_REVISION: The revision of the package. Defaults to 1
EOF
fi