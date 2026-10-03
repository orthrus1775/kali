$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

Write-Host "==> ansible-playbook --syntax-check"
ansible-playbook --syntax-check main.yml
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if (Get-Command ansible-lint -ErrorAction SilentlyContinue) {
  Write-Host "==> ansible-lint"
  ansible-lint
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} else {
  Write-Host "==> ansible-lint not installed, skipping"
}

if (Get-Command packer -ErrorAction SilentlyContinue) {
  Write-Host "==> packer validate"
  packer validate (Join-Path (Get-Location) "packer")
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} else {
  Write-Host "==> packer not installed, skipping"
}

Write-Host "==> ok"
