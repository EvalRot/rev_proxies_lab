#!/bin/sh
set -e

# Optional: install tcpdump for on-demand packet inspection (as in compose config)
apt-get update \
  && apt-get install -y tcpdump \
  && rm -rf /var/lib/apt/lists/*

if [ "${PY_DEBUGPY}" = "1" ]; then
  # Sanitize DEBUGPY_PORT to avoid CR/LF from Windows line endings
  PORT="$(printf '%s' "${DEBUGPY_PORT:-5678}" | tr -d '\r\n')"
  export DEBUGPY_PORT="${PORT}"
  echo "[entrypoint] debugpy mode on; worker will wait on ${DEBUGPY_PORT} via post_fork"
fi

set -- gunicorn -c /app/gunicorn.conf.py
if [ -n "${GUNICORN_FORWARDED_ALLOW_IPS:-}" ]; then
  set -- "$@" --forwarded-allow-ips "${GUNICORN_FORWARDED_ALLOW_IPS}"
fi

exec "$@"
