install:
	./scripts/$@.sh

start:
	./scripts/$@.sh

restart:
	./scripts/$@.sh

stop:
	./scripts/$@.sh

macvlan:
	./scripts/$@.sh

backup:
	./scripts/$@.sh

debug.service:
	journalctl -u start-geck.service -b