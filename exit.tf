# Migrated Debian VM, its cloud-init ISO is left over from main.tf
resource "libvirt_domain" "exit" {
  provider    = libvirt.virt3
  name        = "exit"
  memory      = 512
  memory_unit = "MiB"
  vcpu        = 1
  type        = "kvm"
  autostart   = true

  cpu = {
    mode = "host-passthrough"
  }

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
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
            file = "/var/lib/libvirt/images/exit.qcow2"
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
        driver = {
          type    = "qcow2"
          discard = "unmap"
        }
      },
      {
        device = "cdrom"
        source = {
          file = {
            file = "/var/lib/libvirt/images/exit-cloudinit.iso"
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
        mac   = { address = var.mac_addresses["exit"] }
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

    channels = [
      {
        source = { unix = { mode = "bind" } }
        target = { virt_io = { name = "org.qemu.guest_agent.0" } }
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

    mem_balloon = {
      model               = "virtio"
      free_page_reporting = "on"
    }
  }

  running = true
}
