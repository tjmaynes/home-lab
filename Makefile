DEFAULT_ENV_FILE := .envrc.development.$(shell arch)
ENV_FILE := $(or ${ENV_FILE}, ${DEFAULT_ENV_FILE})

include $(ENV_FILE)
export $(shell sed 's/=.*//' $(ENV_FILE))

export PUID := $(shell id -u)
export PGID := $(shell id -g)

install:
	./scripts/runner.sh "$@"

start:
	./scripts/runner.sh "$@"

backup:
	./scripts/runner.sh "$@"

stop:
	./scripts/runner.sh "$@"