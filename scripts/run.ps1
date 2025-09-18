param(
  [ValidateSet('up','down','logs')]
  [string]$Action = 'up',
  [ValidateSet('nginx')]
  [string]$Proxy = 'nginx',
  [ValidateSet('python','php')]
  [string[]]$Backend = @('python'),
  [int]$Port = 8080,
  [string]$NginxConf = 'services/proxies/nginx/conf/base.conf'
)

$ErrorActionPreference = 'Stop'

function ComposeCmd {
  param([string]$CmdArgs)
  $cmd = "docker compose -f compose/base.yml -f compose/proxies.yml -f compose/backends.yml $CmdArgs"
  Write-Host "-> $cmd" -ForegroundColor Cyan
  iex $cmd
}

if ($Proxy -ne 'nginx') { throw "Only nginx proxy is scaffolded in this starter." }
# Validate backends
foreach ($b in $Backend) {
  if (@('python','php') -notcontains $b) { throw "Unsupported backend: $b" }
}

$env:NGINX_HOST_PORT = "$Port"
$env:NGINX_CONF = (Resolve-Path $NginxConf).Path

$profiles = @("--profile $Proxy") + ($Backend | ForEach-Object { "--profile $_" })

switch ($Action) {
  'up' {
    ComposeCmd ("{0} up -d --build" -f ($profiles -join ' '))
  }
  'down' {
    ComposeCmd ("{0} down -v" -f ($profiles -join ' '))
  }
  'logs' {
    ComposeCmd ("{0} logs -f --tail=100" -f ($profiles -join ' '))
  }
}
