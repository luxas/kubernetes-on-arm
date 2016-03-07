cd "$( dirname "${BASH_SOURCE[0]}" )"

cp ../../version.sh .

# First, build
docker build -t kubernetesonarm/build .

# Then copy out the binaries
CID=$(docker run -d kubernetesonarm/build /bin/bash)
BIN=$(pwd)/../_bin
OUT=$BIN/latest

# If there is a latest version, move to build date
if [[ -d "$OUT" ]]; then
	# Now is the variable $BUILD_DATE available, which is the latest build date
	source "$OUT/version.sh"

	# Move latest to build date
	mv $OUT $BIN/$BUILD_DATE
fi

# Create the latest dir
mkdir -p $OUT

# Copy over all binaries, now the binaries are in _bin/latest/bin
docker cp $CID:/build/bin $OUT

# It shouldn't be like that, move everything to _bin/latest
mv $OUT/bin/* $OUT
rm -r $OUT/bin

# Copy the version file to our directory
cp ../../version.sh $OUT/version.sh

# And append the build date
echo -e "\nBUILD_DATE=\"$(date +%d%m%y_%H%M)\"" >> $OUT/version.sh

#rm -f /usr/bin/kubectl
#cp $OUT/kubectl /usr/bin/

# Remove the temporary container, saves space
docker rm $CID