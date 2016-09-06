#!/usr/bin/env bash
SCRIPTDIR=`dirname "$BASH_SOURCE"`
cp $SCRIPTDIR/system-docker.socket /lib/systemd/system
systemctl enable system-docker.socket
cp $SCRIPTDIR/system-docker.service /lib/systemd/system
systemctl enable system-docker.service
