install:
	chmod +x ./scripts/$@.sh
	./scripts/$@.sh

boot:
	./scripts/run.sh "$@"

start:
	./scripts/run.sh "$@"

restart:
	./scripts/run.sh "$@"

stop:
	chmod +x ./scripts/$@.sh
	./scripts/$@.sh

backup:
	chmod +x ./scripts/$@.sh
	./scripts/$@.sh

debug:
	journalctl -u geck.service -b

debug.ports:
	 lsof -i -P -n | grep LISTEN

local_plex_pipe:
	chmod +x ./scripts/local-plex-pipe.sh
	./scripts/local-plex-pipe.sh