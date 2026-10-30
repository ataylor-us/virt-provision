# Home Assistant OS, moved from another box
# Boots UEFI off its own disk, no cloud-init
resource "libvirt_domain" "haos" {
  name        = "haos"
  memory      = 4096
  memory_unit = "MiB"
  vcpu        = 2
  type        = "kvm"
  autostart   = true

  cpu = {
    mode = "host-passthrough"
  }

  os = {
    type            = "hvm"
    type_arch       = "x86_64"
    type_machine    = "q35"
    loader          = "/usr/share/OVMF/OVMF_CODE_4M.fd"
    # Errored without this
    loader_readonly = "yes"
    loader_type     = "pflash"
    nv_ram = {
      nv_ram   = "/var/lib/libvirt/qemu/nvram/haos_VARS.fd"
      template = "/usr/share/OVMF/OVMF_VARS_4M.fd"
    }
    boot_devices = [{ dev = "hd" }]
  }

  features = {
    acpi = true
    apic = {}
  }

  devices = {
    disks = [
      {
        source = {
          file = {
            file = "/var/lib/libvirt/images/haos_ova-18.1.qcow2"
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
        driver = {
          type = "qcow2"
        }
      }
    ]

    interfaces = [
      {
        model = { type = "virtio" }
        mac   = { address = var.mac_addresses["haos"] }
        source = {
          bridge = {
            bridge = "br0"
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

    rngs = [
      {
        model   = "virtio"
        backend = { random = "/dev/urandom" }
      }
    ]
  }

  running = true
}
