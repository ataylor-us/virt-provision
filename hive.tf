# (Legacy?) AlmaLinux 10 puppet/openbox VM
resource "libvirt_domain" "hive" {
  name        = "hive"
  memory      = 6144
  memory_unit = "MiB"
  vcpu        = 4
  type        = "kvm"
  autostart   = true

  cpu = {
    mode = "host-passthrough"
  }

  os = {
    type      = "hvm"
    type_arch = "x86_64"
    # Legacy - Please keep
    type_machine = "pc"
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
            file = "/var/lib/libvirt/images/hive.qcow2"
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
      }
    ]

    interfaces = [
      {
        model = { type = "virtio" }
        mac   = { address = var.mac_addresses["hive"] }
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
