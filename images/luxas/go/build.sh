cd "$( dirname "${BASH_SOURCE[0]}" )"

# Use the version file
cp ../../version.sh .

# Build the image
docker build -t luxas/go .
