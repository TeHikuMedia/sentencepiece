set -ex

make corpus -j
make models/sample_corpus.model

# Send text corpus to /output
cp -r ../corpus /output

# Send model to /output
cp sample_corpus.sentences /output
cp -r models/ /output
