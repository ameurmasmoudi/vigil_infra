resource "libvirt_network" "vigil" {
  name      = "vigil"
  autostart = true

  forward = {
    mode = "nat"
  }

  bridge = {
    name = "virbr-vigil"
  }

  domain = {
    name       = "vigil.internal"
    local_only = "yes"
  }

  ips = [
    {
      address = local.gateway
      prefix  = local.prefix
      dhcp = {
        hosts = [
          for name, node in local.nodes : {
            mac  = node.mac
            ip   = node.ip
            name = name
          }
        ]
      }
    }
  ]
}
