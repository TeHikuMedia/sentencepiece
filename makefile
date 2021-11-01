REPO_NAME := $(shell basename `git rev-parse --show-toplevel` | tr '[:upper:]' '[:lower:]')
GIT_TAG ?= $(shell git log --oneline | head -n1 | awk '{print $$1}')
DOCKER_REGISTRY := 473856431958.dkr.ecr.ap-southeast-2.amazonaws.com
IMAGE := $(DOCKER_REGISTRY)/$(REPO_NAME)
HAS_DOCKER ?= $(shell which docker)
RUN ?= $(if $(HAS_DOCKER), docker run $(DOCKER_ARGS) --rm -v $$(pwd)/..:/home/kaimahi/language-models -w /home/kaimahi/language-models/$(REPO_NAME) -u $(UID):$(GID) $(IMAGE))
UID ?= kaimahi
GID ?= kaimahi
DOCKER_ARGS ?=
LOG_LEVEL ?= INFO

.PHONY: docker docker-push docker-pull enter enter-root

train: models/full_corpus.model models/sample_corpus.model
models/full_corpus.model: full_corpus.sentences
	$(RUN) spm_train --input=$< --model_prefix=models/full_corpus --vocab_size=8000 --character_coverage=1.0 --model_type=unigram

models/sample_corpus.model: sample_corpus.sentences
	$(RUN) spm_train --input=$< --model_prefix=models/sample_corpus --vocab_size=1000 --character_coverage=1.0 --model_type=unigram

full_corpus.sentences: scripts/prepare_sentences.py
	$(RUN) python3 $< --corpus_dir ../corpus --sentence_file $@ --log_level $(LOG_LEVEL)

SAMPLE_SIZE ?= 1000
sample_corpus.sentences: scripts/prepare_sentences.py
	$(RUN) python3 $< --corpus_dir ../corpus --sentence_file $@ --sample_size $(SAMPLE_SIZE) --log_level $(LOG_LEVEL)

clean:
	rm -rf models/* *.sentences

JUPYTER_PASSWORD ?= jupyter
JUPYTER_PORT ?= 8888
.PHONY: jupyter
jupyter: UID=root
jupyter: GID=root
jupyter: DOCKER_ARGS=-u $(UID):$(GID) --rm -it -p $(JUPYTER_PORT):$(JUPYTER_PORT) -e NB_USER=$$USER -e NB_UID=$(UID) -e NB_GID=$(GID)
jupyter:
	$(RUN) jupyter lab \
		--allow-root \
		--port $(JUPYTER_PORT) \
		--ip 0.0.0.0 \
		--NotebookApp.password=$(shell $(RUN) \
			python3 -c \
			"from IPython.lib import passwd; print(passwd('$(JUPYTER_PASSWORD)'))")

.PHONY: docker-login
docker-login: PROFILE=default
docker-login:
	# First run `$$aws configure` to get your AWS credentials in the right place
	docker login -u AWS --password \
	$$(aws ecr get-login-password --profile $(PROFILE) --region ap-southeast-2) \
	"$(DOCKER_REGISTRY)"

docker: docker-login
	docker build $(DOCKER_ARGS) -t $(IMAGE) .
	docker tag $(IMAGE) $(IMAGE):$(GIT_TAG) && docker push $(IMAGE):$(GIT_TAG)
	docker tag $(IMAGE) $(IMAGE):latest && docker push $(IMAGE):latest
	docker push $(IMAGE)

docker-pull:
	docker pull $(IMAGE):$(GIT_TAG)
	docker tag $(IMAGE):$(GIT_TAG) $(IMAGE):latest

enter: DOCKER_ARGS=-it
enter:
	$(RUN) bash

enter-root: DOCKER_ARGS=-it
enter-root: UID=root
enter-root: GID=root
enter-root:
	$(RUN) bash
