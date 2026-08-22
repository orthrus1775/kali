packer {
  required_version = ">= 1.9.0"

  required_plugins {
    vmware = {
      source  = "github.com/hashicorp/vmware"
      version = "~> 1"
    }
  }
}

locals {
  iso_urls = var.iso_url != "" ? [var.iso_url] : [
    "https://cdimage.kali.org/current/kali-linux-${var.kali_version}-installer-amd64.iso",
  ]

  # BIOS/syslinux: Esc to the boot: prompt, then load the installer with the preseed URL.
  boot_command_bios = [
    "<wait><esc><wait>",
    "/install.amd/vmlinuz initrd=/install.amd/initrd.gz ",
    "auto=true priority=critical vga=788 ",
    "hostname=${var.hostname} domain=unassigned-domain ",
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg --- quiet<enter>",
  ]

  # EFI GRUB: open the command prompt, then boot the same installer kernel.
  boot_command_efi = [
    "<wait3s>c<wait3s>",
    "linux /install.amd/vmlinuz auto=true priority=critical vga=788 ",
    "hostname=${var.hostname} domain=unassigned-domain ",
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg --- quiet<enter><wait>",
    "initrd /install.amd/initrd.gz<enter><wait>",
    "boot<enter>",
  ]
}

source "vmware-iso" "kali" {
  iso_urls     = local.iso_urls
  iso_checksum = var.iso_checksum

  vm_name              = var.vm_name
  guest_os_type        = "debian12-64"
  version              = "21"
  cpus                 = var.cpus
  memory               = var.memory
  disk_size            = var.disk_size
  disk_adapter_type    = "sata"
  disk_type_id         = "0"
  network              = var.network
  network_adapter_type = var.network_adapter_type
  usb                  = true
  headless             = var.headless
  firmware             = var.firmware

  # Second NIC is attached after install so preseed only has to pick one interface.
  vmx_data_post = {
    "ethernet1.present"        = "TRUE"
    "ethernet1.startConnected" = "TRUE"
    "ethernet1.connectionType" = var.network2
    "ethernet1.virtualDev"     = var.network_adapter_type
    "ethernet1.addressType"    = "generated"
  }

  http_content = {
    "/preseed.cfg" = templatefile("${path.root}/http/preseed.cfg.pkrtpl", {
      hostname = var.hostname
      timezone = var.timezone
      username = var.ssh_username
      password = var.ssh_password
    })
  }

  boot_wait         = "12s"
  boot_key_interval = "50ms"
  boot_command      = var.firmware == "efi" ? local.boot_command_efi : local.boot_command_bios

  communicator         = "ssh"
  ssh_username         = var.ssh_username
  ssh_password         = var.ssh_password
  ssh_timeout          = "90m"
  ssh_handshake_attempts = 100

  shutdown_command = "sudo /sbin/shutdown -P now"
  shutdown_timeout = "10m"

  output_directory = var.output_directory
  format           = var.format
}

build {
  name    = "kali"
  sources = ["source.vmware-iso.kali"]

  provisioner "shell" {
    execute_command = "sudo -E sh -c '{{ .Vars }} {{ .Path }}'"
    environment_vars = [
      "BUILD_USER=${var.ssh_username}",
      "GIT_REPO=${var.git_repo}",
      "GIT_BRANCH=${var.git_branch}",
      "GIT_DIR=${var.git_dir}",
    ]
    script = "${path.root}/scripts/bootstrap.sh"
  }
}
