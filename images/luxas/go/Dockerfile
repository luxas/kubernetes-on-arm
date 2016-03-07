FROM luxas/raspbian

# Install software in one layer
RUN apt-install --no-install-recommends \
        # Download software
        curl \
        ca-certificates \
        rsync \

        # Version control
        git \
        mercurial \
		
        # Build tools
        gcc \
        g++ \
        make \
        patch \
        libc6-dev \

        # Executable packer
        upx

# Copy version info
COPY version.sh /

# Make goroot and gopath variables
ENV GOROOT=/usr/local/go \
    GOROOT_BOOTSTRAP_PATH=/goroot1.4 \
    GOPATH=/go \
    GOARM=6

# Set the PATH based on GOROOT and GOPATH
ENV PATH=$PATH:$GOROOT/bin:$GOPATH/bin

# Much, much faster to just download instead of compiling from source
RUN chmod +x /version.sh \
    && . /version.sh \
    && mkdir -p $GOROOT $GOROOT_BOOTSTRAP_PATH $GOPATH \
    && curl -sSL https://github.com/hypriot/golang-armbuilds/releases/download/v${GO_VERSION}/go${GO_VERSION}.linux-armv6.tar.gz | tar -xzC $GOROOT --strip-components=1 \
    && go get github.com/tools/godep


# Build go1.4.x in the other layer, run this if GO_BOOTSTRAP_VERSION is set
#RUN . /version.sh \
#	&& if [ ! -z $GO_BOOTSTRAP_VERSION ]; then \
#
#	# Download source code
#	curl -sSL https://golang.org/dl/go$GO_BOOTSTRAP_VERSION.src.tar.gz | tar -xz -C $GOROOT_BOOTSTRAP_PATH --strip-components=1 \
#
#	# Build go
#	&& cd $GOROOT_BOOTSTRAP_PATH/src && ./make.bash; fi

# Build the "real" go version
#RUN . /version.sh \
#	# Download source code
#	&& curl -sSL https://golang.org/dl/go$GO_VERSION.src.tar.gz | tar -xz -C $GOROOT --strip-components=1 \
#
#	# Build go
#	&& cd $GOROOT/src && GOROOT_BOOTSTRAP=$GOROOT_BOOTSTRAP_PATH ./make.bash \
#
#	# Install godep, which is required in many projects
#	&& go get github.com/tools/godep 


# 													HACK													#
# Instead of:
# cd /goroot1.4/src && ./make.bash
#
# One may do this:
# cd /goroot1.4/src && ./make.bash --dist-tool						&& \
# /goroot1.4/pkg/tool/linux_arm/dist bootstrap -v 					&& \
# cp /goroot1.4/pkg/tool/linux_arm/go_bootstrap /goroot1.4/bin/go
#
# This will not build the whole go1.4, but instead build cmd/dist and the go_bootstrap tool, which is renamed to go
# Not sure if reliable, but it compiles
#