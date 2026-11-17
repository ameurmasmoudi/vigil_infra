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
          for h in local.reserved_hosts : {
            mac = local.mac[h]
            ip  = cidrhost(var.network_cidr, h)
          }
        ]
      }
    }
  ]

  lifecycle {
    precondition {
      condition     = alltrue([for n in values(local.nodes) : contains(local.reserved_hosts, n.host)])
      error_message = "Every node's host number must be inside the reserved DHCP block ${local.reserved_first}-${local.reserved_first + local.reserved_count - 1}. Growing the block replaces the network (all VMs lose connectivity until restarted)."
    }
  }
}
