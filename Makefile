.PHONY: build push push_latest clean

NAME := docker-atlassian-bamboo
ORG := haphan
IMAGE := $(ORG)/$(NAME)

VERSION := $(shell date '+%y%m%d.%H%M%S')
TAG_VERSION := $(IMAGE):$(VERSION)
TAG_LATEST := $(IMAGE):latest
TAG_LAST_SUCCESS = $(IMAGE):`cat $(BUILD_FILE)`

INSTANCE := $(NAME)-default
BUILD_DIR := .build
BUILD_FILE := $(BUILD_DIR)/version.txt

build:
	mkdir -p $(BUILD_DIR)
	docker build --no-cache --tag $(TAG_VERSION) .
	echo $(VERSION) > $(BUILD_FILE)

push:
	docker push $(TAG_LAST_SUCCESS)

push_latest: _check_last_success_build
	docker tag $(TAG_LAST_SUCCESS) $(TAG_LATEST)
	docker push $(TAG_LATEST)

run: _check_last_success_build
	docker run -it -d -v /var/run/docker.sock:/var/run/docker.sock -p 8085:8085 -p 54663:54663 --restart=always --name $(INSTANCE) -h $(NAME) \
		$(IMAGE):`cat $(BUILD_FILE)`

sh:
	docker exec -it $(INSTANCE) sh

bash:
	docker exec -it $(INSTANCE) bash

logs:
	docker logs -f $(INSTANCE)

rm:
	@docker rm -f $(INSTANCE) || true

clean: rm
	-@rm -rf $(BUILD_DIR)

_check_last_success_build:
	test -s $(BUILD_FILE) || { echo "No recent build found. Did you forget to run make build ?"; exit 1; }
