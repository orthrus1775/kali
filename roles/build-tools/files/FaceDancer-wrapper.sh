#!/bin/sh
# FaceDancer generates a crate and runs cargo build in $PWD.
# Use the install-time vendored crates and a pinned rustc; do not hit the network.
export PATH="${HOME}/.cargo/bin:${PATH}"
export CARGO_HOME="${CARGO_HOME:-/opt/facedancer-cargo-home}"
export CARGO_NET_OFFLINE="${CARGO_NET_OFFLINE:-true}"
export RUSTUP_AUTO_INSTALL="${RUSTUP_AUTO_INSTALL:-0}"
exec /opt/FaceDancer/FaceDancer "$@"
