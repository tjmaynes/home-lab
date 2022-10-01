install:
	./scripts/$@.sh

start:
	./scripts/$@.sh

restart:
	./scripts/$@.sh

stop:
	./scripts/$@.sh

backup:
	./scripts/$@.sh

debug.service:
	journalctl -u start-geck.service -b

debug.grafana-agent:
	journalctl -b -u grafana-agent.service

debug.promtail-agent:
	journalctl -b -u promtail-agent.service