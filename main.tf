# Based on terraform-provider-libvirt examples/alpine_cloudinit.tf
# Standardized on Debian VMs, may expand in the future
terraform {
  required_version = ">= 1.8"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.9.9"
    }
  }
}

provider "libvirt" {
  uri = "qemu+sshcmd://alex@virt.internal/system"
}

# One entry per VM
# bridge defaults to "br0"
# pool defaults to "default"
# autostart defaults to false
#
# Adding existing = true attaches <name>.qcow2 in the *default* pool, for migrated VMs
locals {
  vms = {
    dev1     = { vcpu = 6, memory_mib = 2048, bridge = "br10", existing = true }
    dev2     = { vcpu = 2, memory_mib = 4096, bridge = "br10", existing = true }
    dev3     = { vcpu = 2, memory_mib = 2048, bridge = "br10", autostart = true, existing = true }
    exit     = { vcpu = 1, memory_mib = 512, autostart = true, existing = true }
    bog      = { vcpu = 2, memory_mib = 2048, bridge = "br11", autostart = true, existing = true }
    frontend = { vcpu = 6, memory_mib = 8192, autostart = true, existing = true }
    hub      = { vcpu = 8, memory_mib = 4096, autostart = true, existing = true }
  }
}

# Exported by .envrc
variable "vm_password_hash" {
  type      = string
  sensitive = true
}

# Exported by .envrc
variable "mac_addresses" {
  type = map(string)
}

resource "libvirt_volume" "debian_base" {
  name = "debian-13-base.qcow2"
  pool = "default"
  target = {
    format = {
      type = "qcow2"
    }
  }
  create = {
    content = {
      url = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
    }
  }
}

resource "libvirt_volume" "disk" {
  for_each = { for k, v in local.vms : k => v if !try(v.existing, false) }

  name = "${each.key}.qcow2"
  pool = try(each.value.pool, "default")
  target = {
    format = {
      type = "qcow2"
    }
  }
  capacity = each.value.disk_gib * 1024 * 1024 * 1024

  backing_store = {
    path = libvirt_volume.debian_base.path
    format = {
      type = "qcow2"
    }
  }
}

resource "libvirt_cloudinit_disk" "seed" {
  for_each = local.vms

  name = "${each.key}-cloudinit"

  user_data = <<-EOF
    #cloud-config
    users:
      - name: alex
        sudo: ALL=(ALL) ALL
        shell: /bin/bash
        passwd: ${var.vm_password_hash}
        lock_passwd: false
        ssh_authorized_keys:
          - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFKo4XAoO9Z4jjpOndjKMQAtR8IRQHbn7m1WaI53Ynho
    ssh_pwauth: false
    # Prevents keys from getting nuked from migrated VMs
    ssh_deletekeys: false
    timezone: America/New_York
  EOF

  meta_data = <<-EOF
    instance-id: ${each.key}-001
    local-hostname: ${each.key}
  EOF
}

resource "libvirt_volume" "seed" {
  for_each = local.vms

  name = "${each.key}-cloudinit.iso"
  pool = try(each.value.pool, "default")

  create = {
    content = {
      url = libvirt_cloudinit_disk.seed[each.key].path
    }
  }
}

resource "libvirt_domain" "vm" {
  for_each = local.vms

  name        = each.key
  memory      = each.value.memory_mib
  memory_unit = "MiB"
  vcpu        = each.value.vcpu
  type        = "kvm"
  autostart   = try(each.value.autostart, false)

  cpu = {
    mode = "host-passthrough"
  }

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
  }

  # Got "D3cold device inaccessible" until I enabled this
  features = {
    acpi = true
    apic = {}
  }

  devices = {
    # AppArmor denies the backing image when attaching by pool/volume. Attaching by path
    disks = [
      {
        source = {
          file = {
            file = try(each.value.existing, false) ? "/var/lib/libvirt/images/${each.key}.qcow2" : libvirt_volume.disk[each.key].path
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
        driver = {
          type = "qcow2"
        }
      },
      {
        device = "cdrom"
        source = {
          file = {
            file = libvirt_volume.seed[each.key].path
          }
        }
        target = {
          dev = "sda"
          bus = "sata"
        }
      }
    ]

    interfaces = [
      {
        model = { type = "virtio" }
        mac   = { address = var.mac_addresses[each.key] }
        source = {
          bridge = {
            bridge = try(each.value.bridge, "br0")
          }
        }
      }
    ]

    consoles = [
      {
        target = { type = "serial", port = 0 }
      }
    ]

    graphics = [
      {
        vnc = {
          auto_port = true
          listen    = "127.0.0.1"
        }
      }
    ]

    # Uses host /dev/urandom
    rngs = [
      {
        model   = "virtio"
        backend = { random = "/dev/urandom" }
      }
    ]
  }

  running = true
}
