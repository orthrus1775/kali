variable "kali_version" {
  type        = string
  default     = "2026.2"
  description = "Kali release used when iso_url is empty. Must match the ISO that iso_checksum belongs to."
}

variable "iso_url" {
  type        = string
  default     = ""
  description = "Optional full URL or local path to the installer ISO. Overrides kali_version."
}

variable "iso_checksum" {
  type        = string
  default     = "sha256:6dbefacc95e3b556c19c48e8bae39b8b505e2d3a1aba0bfb7ab62b036c3d2ba3"
  description = "Checksum of kali-linux-2026.2-installer-amd64.iso. Change this if you change kali_version or iso_url."
}

variable "vm_name" {
  type    = string
  default = "CL26Kali"
}

variable "hostname" {
  type    = string
  default = "kali"
}

variable "timezone" {
  type    = string
  default = "US/Eastern"
}

variable "ssh_username" {
  type    = string
  default = "attacker"
}

variable "ssh_password" {
  type      = string
  default   = "GoCyber2026!!"
  sensitive = true
}

variable "git_repo" {
  type        = string
  default     = "https://github.com/orthrus1775/kali.git"
  description = "Cloned into ~/<repo-dir> during bootstrap."
}

variable "git_dir" {
  type        = string
  default     = "kali"
  description = "Directory name under the guest home for the clone."
}

variable "cpus" {
  type    = number
  default = 2
}

variable "memory" {
  type        = number
  default     = 16384
  description = "RAM in MiB (16 GiB)."
}

variable "disk_size" {
  type        = number
  default     = 131072
  description = "Disk size in MiB (128 GiB)."
}

variable "network" {
  type        = string
  default     = "nat"
  description = "First NIC. nat, hostonly, or bridged."
}

variable "network2" {
  type        = string
  default     = "hostonly"
  description = "Second NIC, added after the install. nat, hostonly, or bridged."
}

variable "network_adapter_type" {
  type    = string
  default = "e1000"
}

variable "headless" {
  type    = bool
  default = false
}

variable "firmware" {
  type        = string
  default     = "bios"
  description = "bios matches the Kali installer splash menu. Use efi only if the VM boots GRUB instead."
}

variable "output_directory" {
  type    = string
  default = "output-kali"
}

variable "format" {
  type        = string
  default     = "vmx"
  description = "vmx opens directly in Workstation. ova/ovf requires VMware OVF Tool on PATH."
}
