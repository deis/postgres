include includes.mk

# Short name, following [a-zA-Z_], used all over the place.
SHORT_NAME := postgres

# SemVer with build information is defined in the SemVer 2 spec, but Docker
# doesn't allow +, so we use -.
VERSION := 0.0.1-$(shell date "+%Y%m%d%H%M%S")

# Legacy support for DEV_REGISTRY, plus new support for DEIS_REGISTRY.
DEIS_REGISTRY ?= ${DEV_REGISTRY}

IMAGE_PREFIX ?= deis/

IMAGE := ${DEIS_REGISTRY}/${IMAGE_PREFIX}${SHORT_NAME}:${VERSION}

all:
	@echo "Use a Makefile to control top-level building of the project."

build: docker-build

docker-build: check-docker
	docker build --rm -t ${IMAGE} rootfs

docker-push: check-docker check-registry
	docker push ${IMAGE}

test:
	@echo "No tests"

.PHONY: all build
