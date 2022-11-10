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

debug.grafana-agent:
	journalctl -b -u grafana-agent.service

debug.promtail-agent:
	journalctl -b -u promtail-agent.service