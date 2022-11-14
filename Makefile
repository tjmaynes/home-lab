install:
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

debug.service:
	journalctl -u start-geck.service -b

debug.cloudflare-tunnel:
	journalctl -b -u start-cloudflare-tunnel.service

local_plex_pipe:
	chmod +x ./scripts/local-pipe.sh
	./scripts/local-pipe.sh