# Short name: Short name, following [a-zA-Z_], used all over the place.
# Some uses for short name:
# - Docker image name
# - Kubernetes service, rc, pod, secret, volume names
SHORT_NAME := postgres

VERSION ?= git-$(shell git rev-parse --short HEAD)

# Legacy support for DEV_REGISTRY, plus new support for DEIS_REGISTRY.
DEIS_REGISTY ?= ${DEV_REGISTRY}/
IMAGE_PREFIX ?= deis

# Canonical docker image name
IMAGE := ${DEIS_REGISTRY}${IMAGE_PREFIX}/${SHORT_NAME}:${VERSION}

all: docker-build docker-push

# For cases where we're building from local
# We also alter the RC file to set the image name.
docker-build:
	docker build --rm -t ${IMAGE} rootfs

# Push to a registry that Kubernetes can access.
docker-push:
	docker push ${IMAGE}

test:
	contrib/ci/test.sh ${IMAGE}

.PHONY: all docker-build docker-push test
