resource "libvirt_volume" "disk" {
  for_each = local.nodes

  name     = "${each.key}.qcow2"
  pool     = libvirt_pool.vigil.name
  capacity = each.value.disk_gb * 1024 * 1024 * 1024

  target = {
    format = {
      type = "qcow2"
    }
  }

  backing_store = {
    path = libvirt_volume.base.path
    format = {
      type = "qcow2"
    }
  }
}

resource "libvirt_cloudinit_disk" "init" {
  for_each = local.nodes

  name = "${each.key}-cloudinit"

  meta_data = yamlencode({
    instance-id    = each.key
    local-hostname = each.key
  })

  user_data = templatefile("${path.module}/cloud-init/user-data.yaml.tftpl", {
    user           = var.ssh_user
    ssh_public_key = local.ssh_public_key
  })

  network_config = file("${path.module}/cloud-init/network-config.yaml")
}

resource "libvirt_volume" "cloudinit" {
  for_each = local.nodes

  name = "${each.key}-cloudinit.iso"
  pool = libvirt_pool.vigil.name

  create = {
    content = {
      url = libvirt_cloudinit_disk.init[each.key].path
    }
  }
}

resource "libvirt_domain" "node" {
  for_each = local.nodes

  name        = each.key
  type        = "kvm"
  vcpu        = each.value.vcpu
  memory      = each.value.memory_mb * 1024
  memory_unit = "KiB"
  running     = true

  cpu = {
    mode = "host-passthrough"
  }

  features = {
    acpi = true
    apic = {}
  }

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
  }

  devices = {
    disks = [
      {
        source = {
          volume = {
            pool   = libvirt_volume.disk[each.key].pool
            volume = libvirt_volume.disk[each.key].name
          }
        }
        target = {
          bus = "virtio"
          dev = "vda"
        }
        driver = {
          type = "qcow2"
        }
      },
      {
        device = "cdrom"
        source = {
          volume = {
            pool   = libvirt_volume.cloudinit[each.key].pool
            volume = libvirt_volume.cloudinit[each.key].name
          }
        }
        target = {
          bus = "sata"
          dev = "sda"
        }
      }
    ]

    interfaces = [
      {
        type  = "network"
        model = { type = "virtio" }
        mac   = { address = each.value.mac }
        source = {
          network = {
            network = libvirt_network.vigil.name
          }
        }
      }
    ]

    serials = [
      {
        target = { type = "isa-serial", port = 0 }
      }
    ]

    rngs = [
      {
        model   = "virtio"
        backend = { random = "/dev/urandom" }
      }
    ]
  }
}
