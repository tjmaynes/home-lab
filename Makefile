install:
	chmod +x ./scripts/$@.sh
	./scripts/$@.sh

boot:
	chmod +x ./scripts/$@.sh
	./scripts/$@.sh

start:
	chmod +x ./scripts/$@.sh
	./scripts/$@.sh

restart:
	chmod +x ./scripts/$@.sh
	./scripts/$@.sh

stop:
	chmod +x ./scripts/$@.sh
	./scripts/$@.sh

backup:
	chmod +x ./scripts/$@.sh
	./scripts/$@.sh

debug:
	journalctl -u geck.service -b

local_plex_pipe:
	chmod +x ./scripts/local-plex-pipe.sh
	./scripts/local-plex-pipe.sh