locals {
  image      = jsondecode(file("${path.module}/image.json"))
  image_path = pathexpand("~/.cache/vigil/images/${local.image.name}-${local.image.release}.img")

  gateway        = cidrhost(var.network_cidr, 1)
  prefix         = tonumber(split("/", var.network_cidr)[1])
  mac            = { for h in range(2, 255) : h => format("52:54:00:77:00:%02x", h) }
  ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))

  reserved_first = 10
  reserved_count = 20
  reserved_hosts = range(local.reserved_first, local.reserved_first + local.reserved_count)

  nodes = {
    for name, node in var.nodes : name => merge(node, {
      ip  = cidrhost(var.network_cidr, node.host)
      mac = local.mac[node.host]
    })
  }
}
