#!/bin/sh
# Convert CRLF text files in this Kali Ansible/Packer repo after a Windows copy.
ROOT="${1:-$(pwd)}"
cd "$ROOT" || exit 1

find "$PWD" \
  \( -path "$PWD/.git" \
     -o -path "$PWD/packer/output-*" \
     -o -path "$PWD/packer/packer_cache" \
     -o -path "$PWD/packer_cache" \
     -o -path "$PWD/output-*" \
  \) -prune -o \
  -type f \( \
    -name '*.sh' -o -name '*.py' -o -name '*.yml' -o -name '*.yaml' \
    -o -name '*.j2' -o -name '*.cfg' -o -name '*.ini' -o -name '*.axs' \
    -o -name '*.ps1' -o -name '*.desktop' -o -name '*.xml' -o -name '*.json' \
    -o -name '*.conf' -o -name '*.toml' -o -name '*.pkrtpl' -o -name '*.hcl' \
    -o -name '*.cna' \
  \) -print0 \
  | xargs -0 -r dos2unix -q
