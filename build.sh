set -ex

make train

# Send text corpus to /output
cp -r ../corpus /output

# Send model to /output
cp *.sentences /output
cp -r models/ /output
