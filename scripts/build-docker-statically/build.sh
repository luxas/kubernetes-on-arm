#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )"

DOCKER_BRANCH=${DOCKER_BRANCH:-"v1.10.2"}

# Download docker
git clone https://github.com/docker/docker

cd docker

git checkout $DOCKER_BRANCH

# Patch docker
#mv vendor/src/github.com/opencontainers/runc/libcontainer/seccomp/jump_{amd64,linux}.go
#sed -i 's/,amd64//' vendor/src/github.com/opencontainers/runc/libcontainer/seccomp/jump_linux.go

# Copy the Dockerfile from kubernetes-on-arm source to docker build dir
#cp -f $DOCKERFILEDIR/Dockerfile .

# Customize the dockerfile for armv6 and 1.8.x => start with a 1.8.2 umiddleb/armhf Dockerfile
#curl -sSL https://raw.githubusercontent.com/umiddelb/armhf/ed1d3b1dcd6bd4112b2183c93996a4d4379aed7c/Dockerfile.armv7 > Dockerfile

# Change GOARM and base image. armv7 doesn't run on armv6
sed -e "s@GOARM 7@GOARM 6@" -i Dockerfile.armhf
sed -e "s@armhf/ubuntu:trusty@resin/rpi-raspbian:jessie@" -i Dockerfile.armhf

# Comment out these lines
#sed -e "s@s3cmd=@#s3cmd=@" -i Dockerfile
#sed -e "s@RUN gem install --no-rdoc --no-ri fpm@#RUN gem install --no-rdoc --no-ri fpm@" -i Dockerfile

# Install make if needed
if [[ -f $(which pacman 2>&1) ]]; then
	pacman -S make --noconfirm --needed
fi

# The actual build
time make binary