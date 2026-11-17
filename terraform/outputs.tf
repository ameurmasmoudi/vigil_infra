output "nodes" {
  value = {
    for name, node in local.nodes : name => {
      role = node.role
      ip   = node.ip
    }
  }
}

output "ssh_user" {
  value = var.ssh_user
}
