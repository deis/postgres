check-docker:
	@if [ -z $$(which docker) ]; then \
		echo "Missing \`docker\` client which is required for development"; \
		exit 2; \
	fi

check-registry:
	@if [ -z "$$DEIS_REGISTRY" ] && [ -z "$$DEV_REGISTRY" ]; then \
		echo "DEIS_REGISTRY is not exported"; \
		exit 2; \
	fi
