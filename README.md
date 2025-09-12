Reverse Proxy Inconsistency Lab

Purpose: a small, reproducible lab to chain reverse proxies and backends, explore misconfigurations, and catch inconsistencies in parsing/forwarding behavior.

Quick start (Docker Desktop required):
- Bring up Nginx -> Python (Flask) echo backend:
  - PowerShell: `pwsh scripts/run.ps1 -Action up -Proxy nginx -Backend python`
  - Bash: `./scripts/run.sh -a up -p nginx -b python`
- Drive requests with your tool of choice (e.g., Burp) to `http://localhost:8080`.
- Tail logs:
  - PowerShell: `pwsh scripts/run.ps1 -Action logs -Proxy nginx -Backend python`
  - Bash: `./scripts/run.sh -a logs -p nginx -b python`
- Tear down:
  - PowerShell: `pwsh scripts/run.ps1 -Action down -Proxy nginx -Backend python`
  - Bash: `./scripts/run.sh -a down -p nginx -b python`

Layout:
- `services/backends/python/` — Flask echo application behind Gunicorn.
- `services/proxies/nginx/` — Nginx image + base config and a couple misconfig variants.
- `compose/` — base networks and per-layer compose files with profiles.
- `scenarios/` — example scenario file (YAML) for future orchestration.
- `scripts/` — helper PowerShell to up/down/logs.
- `tools/` — simple raw sender + runner stub for scenarios.

Notes:
- Backend echo uses Flask (via Gunicorn) and returns method, URL, path, query args, headers, and base64 body. Header duplicates may be merged by WSGI stacks.
- The app logs each received request (method, full_path, host, remote_addr, body length) to stdout; view via `logs` action.
- Start with a single proxy and backend; extend by adding more services under `services/proxies/*` and `services/backends/*`, then reference via compose profiles.
- On Windows, paths in Compose are relative to the repo root. Docker Desktop must have file sharing enabled for this folder.
