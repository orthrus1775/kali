#!/bin/sh
set -eu

export DEBIAN_FRONTEND=noninteractive

BUILD_USER="${BUILD_USER:-attacker}"
GIT_REPO="${GIT_REPO:-https://github.com/orthrus1775/kali.git}"
GIT_BRANCH="${GIT_BRANCH:-CL2026}"
GIT_DIR="${GIT_DIR:-kali}"
HOME_DIR="/home/${BUILD_USER}"
CLONE_PATH="${HOME_DIR}/${GIT_DIR}"

apt-get update
apt-get install -y git ansible python3-apt open-vm-tools-desktop curl ca-certificates dos2unix

systemctl enable --now ssh
systemctl enable --now open-vm-tools || true

if [ ! -d "${CLONE_PATH}/.git" ]; then
  rm -rf "${CLONE_PATH}"
  sudo -u "${BUILD_USER}" git clone --branch "${GIT_BRANCH}" --single-branch "${GIT_REPO}" "${CLONE_PATH}"
fi

chown -R "${BUILD_USER}:${BUILD_USER}" "${CLONE_PATH}"

dos2unix -q "${CLONE_PATH}/scripts/fix-line-endings.sh" 2>/dev/null || true
if [ -f "${CLONE_PATH}/scripts/fix-line-endings.sh" ]; then
  sh "${CLONE_PATH}/scripts/fix-line-endings.sh" "${CLONE_PATH}"
else
  find "${CLONE_PATH}" \
    \( -path "${CLONE_PATH}/.git" \
       -o -path "${CLONE_PATH}/packer/output-*" \
       -o -path "${CLONE_PATH}/packer/packer_cache" \
       -o -path "${CLONE_PATH}/packer_cache" \
       -o -path "${CLONE_PATH}/output-*" \
    \) -prune -o \
    -type f \( -name '*.sh' -o -name '*.py' -o -name '*.yml' -o -name '*.yaml' -o -name '*.j2' -o -name '*.cfg' -o -name '*.ini' -o -name '*.axs' -o -name '*.pkrtpl' -o -name '*.hcl' \) -print0 \
    | xargs -0 -r dos2unix -q
fi
