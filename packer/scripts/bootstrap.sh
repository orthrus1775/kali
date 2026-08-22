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
apt-get install -y git ansible python3-apt open-vm-tools-desktop curl ca-certificates

systemctl enable --now ssh
systemctl enable --now open-vm-tools || true

if [ ! -d "${CLONE_PATH}/.git" ]; then
  rm -rf "${CLONE_PATH}"
  sudo -u "${BUILD_USER}" git clone --branch "${GIT_BRANCH}" --single-branch "${GIT_REPO}" "${CLONE_PATH}"
fi

chown -R "${BUILD_USER}:${BUILD_USER}" "${CLONE_PATH}"

cat >/etc/motd <<EOF
Kali image from Packer.

Customization repo: ${CLONE_PATH}

  cd ~/${GIT_DIR}
  ansible-playbook main.yml -K

EOF
