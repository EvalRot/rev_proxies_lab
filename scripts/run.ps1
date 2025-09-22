param(
  [ValidateSet('up','down','logs','debug-py')]
  [string]$Action = 'up',
  [ValidateSet('nginx')]
  [string]$Proxy = 'nginx',
  [ValidateSet('python','php')]
  [string[]]$Backend = @('python'),
  [int]$Port = 8080,
  [int]$DebugpyPort = 5678,
  [string]$NginxConf = 'services/proxies/nginx/conf/base.conf',
  [switch]$ForwardedAllowAll
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

Remove-Item Env:PY_DEBUGPY -ErrorAction SilentlyContinue
Remove-Item Env:PYTHON_DEBUGPY_PORT -ErrorAction SilentlyContinue
Remove-Item Env:PYTHON_FORWARDED_ALLOW_IPS -ErrorAction SilentlyContinue

$forwardEnvSet = $false
if ($ForwardedAllowAll) {
  $env:PYTHON_FORWARDED_ALLOW_IPS = '*'
  $forwardEnvSet = $true
}

switch ($Action) {
  'debug-py' {
    Write-Host ("Bringing up services in debugpy mode (waiting for debugger on port {0})..." -f $DebugpyPort)
    $env:PY_DEBUGPY = '1'
    $env:PYTHON_DEBUGPY_PORT = [string]$DebugpyPort
    try {
      ComposeCmd ("{0} up --build" -f ($profiles -join ' '))
    }
    finally {
      Remove-Item Env:PY_DEBUGPY -ErrorAction SilentlyContinue
      Remove-Item Env:PYTHON_DEBUGPY_PORT -ErrorAction SilentlyContinue
      if ($forwardEnvSet) { Remove-Item Env:PYTHON_FORWARDED_ALLOW_IPS -ErrorAction SilentlyContinue }
    }
  }
  'up' {
    ComposeCmd ("{0} up -d --build" -f ($profiles -join ' '))
    if ($forwardEnvSet) { Remove-Item Env:PYTHON_FORWARDED_ALLOW_IPS -ErrorAction SilentlyContinue }
  }
  'down' {
    ComposeCmd ("{0} down -v" -f ($profiles -join ' '))
    if ($forwardEnvSet) { Remove-Item Env:PYTHON_FORWARDED_ALLOW_IPS -ErrorAction SilentlyContinue }
  }
  'logs' {
    ComposeCmd ("{0} logs -f --tail=100" -f ($profiles -join ' '))
    if ($forwardEnvSet) { Remove-Item Env:PYTHON_FORWARDED_ALLOW_IPS -ErrorAction SilentlyContinue }
  }
}
