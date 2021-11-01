set -ex

make corpus
make models/sample_corpus.model

cp sample_corpus.sentences /output
cp -r models/* /output
