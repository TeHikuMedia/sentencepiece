set -ex

echo Here is a greeting ${GREETING}

make train

# Send text corpus to /output
cp -r ../corpus /output

# Send model to /output
cp -r models/ /output
