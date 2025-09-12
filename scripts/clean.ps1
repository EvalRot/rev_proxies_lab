$ErrorActionPreference = 'Stop'
Write-Host "Stopping and removing lab containers..." -ForegroundColor Yellow
docker compose -f compose/base.yml -f compose/proxies.yml -f compose/backends.yml down -v

