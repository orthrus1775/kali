#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

echo "==> ansible-playbook --syntax-check"
ansible-playbook --syntax-check main.yml

if command -v ansible-lint >/dev/null 2>&1; then
  echo "==> ansible-lint"
  ansible-lint
else
  echo "==> ansible-lint not installed, skipping"
fi

if command -v packer >/dev/null 2>&1; then
  echo "==> packer validate"
  packer validate "$root/packer"
else
  echo "==> packer not installed, skipping"
fi

echo "==> ok"
