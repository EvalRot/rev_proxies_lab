#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/run.sh [-a up|down|logs] [-p nginx] [-b python] [-P 8080] [-c services/proxies/nginx/conf/base.conf]

ACTION="up"
PROXY="nginx"
BACKENDS="python"
PORT="8080"
DEBUGPY_PORT="${DEBUGPY_PORT:-5678}"
NGINX_CONF_PATH="services/proxies/nginx/conf/base.conf"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

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

normalize_path() {
  local path="$1"
  if [[ "$path" == /* ]]; then
    printf '%s' "$path"
    return
  fi

  if [[ "$path" =~ ^[A-Za-z]:[\\/].* ]]; then
    printf '%s' "$path"
    return
  fi

  local rel_dir="${path%/*}"
  local rel_base="${path##*/}"
  if [[ "$rel_dir" == "$path" ]]; then
    rel_dir='.'
    rel_base="$path"
  fi

  local resolved
  if resolved=$(cd "$REPO_ROOT" && cd "$rel_dir" 2>/dev/null && pwd); then
    printf '%s/%s' "$resolved" "$rel_base"
  else
    printf '%s/%s' "$REPO_ROOT" "$path"
  fi
}

export NGINX_HOST_PORT="$PORT"
export NGINX_CONF="$(normalize_path "$NGINX_CONF_PATH")"

if [[ ! -f "$NGINX_CONF" ]]; then
  echo "Nginx config file not found: $NGINX_CONF" >&2
  exit 1
fi

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
  debug-py)
    echo "Bringing up services in debugpy mode (waiting for debugger on port ${DEBUGPY_PORT})..."
    export PY_DEBUGPY=1
    export PYTHON_DEBUGPY_PORT="${DEBUGPY_PORT}"
    compose --profile "$PROXY" $(for b in "${BACKEND_ARR[@]}"; do printf -- " --profile %s" "$b"; done) up --build
    rc=$?
    unset PY_DEBUGPY PYTHON_DEBUGPY_PORT
    exit $rc
    ;;
  *)
    echo "Unknown action: $ACTION (expected up|down|logs|debug-py)" >&2
    exit 2
    ;;
esac
