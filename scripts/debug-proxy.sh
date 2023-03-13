#!/usr/bin/env bash

set -e

function main() {
  NGINX_POD=$(kubectl -n media get pod -l app=nginx-proxy-manager -o jsonpath="{.items[0].metadata.name}")
	kubectl -n media exec --stdin --tty "$NGINX_POD" -- /bin/bash
}

main