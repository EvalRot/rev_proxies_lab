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
- Debug Gunicorn via debugpy (waits for your debugger before handling requests):
  - PowerShell: `pwsh scripts/run.ps1 -Action debug-py -Proxy nginx -Backend python [-DebugpyPort 5678]`
  - Bash: `DEBUGPY_PORT=5678 ./scripts/run.sh -a debug-py -p nginx -b python`
  - Attach from VSCode with "Python: Attach using debugpy" targeting `localhost:5678` and map `services/backends/python` -> `/app/services/backends/python`.
- Apply Nginx config changes without bouncing other containers:
  - PowerShell: `docker exec lab_nginx nginx -s reload`
  - Bash: `docker exec lab_nginx nginx -s reload`

Optional Gunicorn flag handling:
- Allow all forwarded IP headers (maps to `gunicorn --forwarded-allow-ips '*'`):
  - PowerShell: add `-ForwardedAllowAll`
  - Bash: add `-F`

Direct backend access (without Nginx)
- Compose publishes host ports for direct testing:
  - Python: `http://localhost:${PYTHON_HOST_PORT:-18080}` (container 8000)
  - PHP: `http://localhost:${PHP_HOST_PORT:-18081}` (container 80)
- Set ports and start both backends:
  - PowerShell: `$env:PYTHON_HOST_PORT=18080; $env:PHP_HOST_PORT=18081; pwsh scripts/run.ps1 -Action up -Proxy nginx -Backend python,php`
  - Bash: `PYTHON_HOST_PORT=18080 PHP_HOST_PORT=18081 ./scripts/run.sh -a up -p nginx -b python,php`
- Then you can point Burp directly to:
  - Python backend: `http://localhost:18080`
  - PHP backend: `http://localhost:18081`

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
