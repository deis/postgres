export GO15VENDOREXPERIMENT=1
VERSION := 0.0.1

all:
	@echo "Use a Makefile to control top-level building of the project."

build:
	@echo "nothing to build"

deploy: kube-service kube-rc

kube-service:
	kubectl create -f def/postgres-service.json

kube-rc:
	kubectl create -f def/postgres-rc.json

kube-clean:
	kubectl delete rc postgres

test:
	@echo "no tests"

.PHONY: all build deploy kube-service kube-rc kube-clean test
