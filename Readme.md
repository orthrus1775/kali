# Tools that help get things done.

Two-stage workflow: Packer builds a Kali VM and clones this repo to `~/kali`. After first boot, run Ansible from that clone.

## Packer (base VM)

Requires [Packer](https://developer.hashicorp.com/packer/install) and VMware Workstation. The template uses the Kali **installer** ISO (not the live image) and a preseeded unattended install.

First time in this directory, install plugins, then build:

```powershell
cd packer
packer init .
packer build .
```

After that, `packer build .` is enough unless the template's required plugins change.

`packer validate .` is optional; it only checks the template, it does not build.

Optional flags (pick what you need, not all of them):

```powershell
# Headless (no VMware GUI)
packer build -var headless=true .

# Local installer ISO instead of downloading (checksum must match that file)
packer build -var iso_url=C:\isos\kali-linux-2026.2-installer-amd64.iso .

# Rebuild over an existing output-kali directory
packer build -force .

# Pause the VM on error so you can inspect the installer
packer build -on-error=ask .

# Export an OVA instead of a Workstation VM (requires ovftool on PATH)
packer build -var format=ova .
```

The guest user is `attacker` / `GoCyber2026!!`. Bootstrap clones https://github.com/orthrus1775/kali.git to `/home/attacker/kali`.

Output is a VMware VM under `packer/output-kali` with 16 GiB RAM, a 128 GiB disk, NAT plus host-only NICs. Open the `.vmx` in Workstation. OVA export needs [OVF Tool](https://developer.broadcom.com/tools/open-virtualization-format-ovf-tool/latest) on PATH and `-var format=ova`.

## Ansible (on the Kali VM)

After you boot the VM:

```sh
cd ~/kali

```

`-K` prompts for the become password. The Packer image also has passwordless sudo for the build user.

## Edit based on individual requirements

[Kali Meta Packages](./roles/install-tools/tasks/apt-stuff.yml)

[C2 Frameworks & Other tools](./roles/build-tools/tasks/main.yml)
