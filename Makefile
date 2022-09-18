install:
	./scripts/runner.sh "$@"

start:
	./scripts/runner.sh "$@"

restart:
	./scripts/runner.sh "$@"

stop:
	./scripts/runner.sh "$@"

backup:
	./scripts/runner.sh "$@"

debug.service:
	journalctl -u start-geck.service -b