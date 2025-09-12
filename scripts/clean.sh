#!/usr/bin/env bash
set -euo pipefail

docker compose -f compose/base.yml -f compose/proxies.yml -f compose/backends.yml down -v

