set -ex

# Create models directory
mkdir models

# Download the text corpus
make corpus -j

# Train the sentencepiece model
make models/full_corpus.model

# Send text corpus to /output
cp -r ../corpus /output

# Send model to /output
cp sample_corpus.sentences /output
cp -r models/ /output
