ENV_FILE := $(or $(ENV_FILE), ./.env.production)

ifneq ("$(wildcard $(ENV_FILE))","")
	include $(ENV_FILE)
	export $(shell sed 's/=.*//' $(ENV_FILE))
endif

include ./.env.default
export $(shell sed 's/=.*//' ./.env.default)

copy_kube_config:
	scp lab@192.168.5.57:~/.kube/config ${HOME}/.kube/config

connect_to_proxy:
	kubectl -n vpn port-forward service/nginx-proxy-manager 8080:80

debug_proxy:
	chmod +x ./scripts/debug-proxy.sh
	./scripts/debug-proxy.sh

connect_to_plex:
	kubectl -n media port-forward service/plex 32400:32400

deploy_servers:
	ansible-playbook ./ansible/setup.yml --ask-become-pass \
		--inventory-file ./ansible/inventory/hosts.ini

deploy_k8s:
	chmod +x ./scripts/run-k8s.sh
	./scripts/run-k8s.sh "apply"

deploy_terraform:
	chmod +x ./scripts/run-terraform.sh
	./scripts/run-terraform.sh "apply"

teardown_k8s:
	chmod +x ./scripts/run-k8s.sh
	./scripts/run-k8s.sh "delete"

teardown_servers:
	ansible-playbook ./ansible/teardown.yml --ask-become-pass \
		--inventory-file ./ansible/inventory/hosts.ini

deploy: deploy_servers deploy_k8s

teardown: teardown_k8s teardown_servers

plan_terraform:
	chmod +x ./scripts/run-terraform.sh
	./scripts/run-terraform.sh "plan"