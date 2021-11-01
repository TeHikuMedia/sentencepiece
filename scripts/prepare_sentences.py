import os
import click
import logging
import itertools as it
from random import shuffle
from utils import multicore_apply
from nltk.tokenize import sent_tokenize


def get_sentences(filepath):
    with open(filepath, 'r') as f:
        sentences = []
        for para in f.read().split('\n'):
            for sent in sent_tokenize(para):
                sent = sent.strip()
                if len(sent) > 0:
                    sentences.append(sent)
        return sentences


@click.command()
@click.option("--corpus_dir", default="INFO", help="Corpus directory")
@click.option("--sentence_file", help="Path to save corpus sentences")
@click.option("--sample_size", type=int,  help="Number of sentences to include in sample corpus")
@click.option("--log_level", default="INFO", help="Log level (default: INFO)")
def main(corpus_dir, sentence_file, sample_size, log_level):
    '''
    Given a corpus directory, prepares a one-sentence-per-line raw corpus file
    '''

    # Set logger config
    logging.basicConfig(
        level=log_level,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )

    file_list = []
    for root, dirs, files in os.walk(corpus_dir):
        for f in files:
            fp = os.path.join(root, f)
            file_list.append(fp)

    sentences = it.chain.from_iterable(
        multicore_apply(file_list, get_sentences)
    )

    if sample_size:
        sentences = list(sentences)
        shuffle(sentences)
        sentences = sentences[:sample_size]

    with open(sentence_file, 'w') as f:
        for sentence in sentences:
            f.write(sentence + '\n')


if __name__ == "__main__":
    main()
