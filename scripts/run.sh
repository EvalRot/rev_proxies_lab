#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/run.sh [-a up|down|logs] [-p nginx] [-b python] [-P 8080] [-c services/proxies/nginx/conf/base.conf]

ACTION="up"
PROXY="nginx"
BACKENDS="python"
PORT="8080"
NGINX_CONF_PATH="services/proxies/nginx/conf/base.conf"

while getopts ":a:p:b:P:c:" opt; do
  case ${opt} in
    a) ACTION="$OPTARG" ;;
    p) PROXY="$OPTARG" ;;
    b) BACKENDS="$OPTARG" ;;
    P) PORT="$OPTARG" ;;
    c) NGINX_CONF_PATH="$OPTARG" ;;
    :) echo "Option -$OPTARG requires an argument" >&2; exit 2 ;;
    \?) echo "Invalid option -$OPTARG" >&2; exit 2 ;;
  esac
done

if [[ "$PROXY" != "nginx" ]]; then
  echo "Only nginx proxy is scaffolded in this starter." >&2
  exit 1
fi
IFS=',' read -r -a BACKEND_ARR <<< "$BACKENDS"
for b in "${BACKEND_ARR[@]}"; do
  case "$b" in
    python|php) ;;
    *) echo "Unsupported backend: $b (expected python|php)" >&2; exit 1 ;;
  esac
done

export NGINX_HOST_PORT="$PORT"
export NGINX_CONF="${NGINX_CONF_PATH}"

compose() {
  docker compose \
    -f compose/base.yml \
    -f compose/proxies.yml \
    -f compose/backends.yml \
    "$@"
}

case "$ACTION" in
  up)
    echo "Bringing up services (proxy=$PROXY backends=$BACKENDS port=$PORT)..."
    compose --profile "$PROXY" $(for b in "${BACKEND_ARR[@]}"; do printf -- " --profile %s" "$b"; done) up -d --build
    ;;
  down)
    echo "Stopping and removing services..."
    compose --profile "$PROXY" $(for b in "${BACKEND_ARR[@]}"; do printf -- " --profile %s" "$b"; done) down -v
    ;;
  logs)
    echo "Tailing logs... (Ctrl-C to stop)"
    compose --profile "$PROXY" $(for b in "${BACKEND_ARR[@]}"; do printf -- " --profile %s" "$b"; done) logs -f --tail=100
    ;;
  *)
    echo "Unknown action: $ACTION (expected up|down|logs)" >&2
    exit 2
    ;;
esac
