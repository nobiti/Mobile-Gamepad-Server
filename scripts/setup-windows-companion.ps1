param(
  [switch]$InstallVigem
)

$ErrorActionPreference = 'Stop'

function Ensure-Command($name) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    throw "Required command not found: $name"
  }
}

Write-Host "[setup] Validating winget..."
Ensure-Command winget

Write-Host "[setup] Installing .NET 8 SDK..."
winget install --id Microsoft.DotNet.SDK.8 --exact --silent --accept-source-agreements --accept-package-agreements

if ($InstallVigem) {
  Write-Host "[setup] Installing ViGEmBus..."
  winget install --id Nefarius.ViGEmBus --exact --silent --accept-source-agreements --accept-package-agreements
} else {
  Write-Host "[setup] Skipping ViGEmBus install. Re-run with -InstallVigem to install automatically."
}

Write-Host "[setup] Windows companion dependencies installed."
