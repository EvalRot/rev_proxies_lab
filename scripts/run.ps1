param(
  [ValidateSet('up','down','logs')]
  [string]$Action = 'up',
  [ValidateSet('nginx')]
  [string]$Proxy = 'nginx',
  [ValidateSet('python')]
  [string]$Backend = 'python',
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
if ($Backend -ne 'python') { throw "Only python backend is scaffolded in this starter." }

$env:NGINX_HOST_PORT = "$Port"
$env:NGINX_CONF = (Resolve-Path $NginxConf).Path

switch ($Action) {
  'up' {
    ComposeCmd "--profile $Proxy --profile $Backend up -d --build"
  }
  'down' {
    ComposeCmd "--profile $Proxy --profile $Backend down -v"
  }
  'logs' {
    ComposeCmd "--profile $Proxy --profile $Backend logs -f --tail=100"
  }
}
