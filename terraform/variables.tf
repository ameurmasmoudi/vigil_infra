variable "network_cidr" {
  type    = string
  default = "10.77.0.0/24"

  validation {
    condition     = can(cidrhost(var.network_cidr, 0)) && endswith(var.network_cidr, "/24")
    error_message = "network_cidr must be a valid /24 IPv4 range."
  }
}

variable "ssh_user" {
  type    = string
  default = "vigil"
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/vigil.pub"
}

variable "nodes" {
  type = map(object({
    role      = string
    vcpu      = number
    memory_mb = number
    disk_gb   = number
    host      = number
  }))

  default = {
    vigil-server = {
      role      = "server"
      vcpu      = 2
      memory_mb = 2048
      disk_gb   = 20
      host      = 10
    }
    vigil-agent-1 = {
      role      = "agent"
      vcpu      = 2
      memory_mb = 3072
      disk_gb   = 20
      host      = 11
    }
    vigil-agent-2 = {
      role      = "agent"
      vcpu      = 2
      memory_mb = 3072
      disk_gb   = 20
      host      = 12
    }
  }

  validation {
    condition     = alltrue([for n in values(var.nodes) : contains(["server", "agent"], n.role)])
    error_message = "Each node's role must be \"server\" or \"agent\"."
  }

  validation {
    condition     = length([for n in values(var.nodes) : n if n.role == "server"]) == 1
    error_message = "Exactly one node must have the role \"server\"."
  }

  validation {
    condition     = alltrue([for n in values(var.nodes) : n.host >= 2 && n.host <= 254])
    error_message = "Each node's host number must be between 2 and 254 (.1 is the gateway)."
  }

  validation {
    condition     = length(distinct([for n in values(var.nodes) : n.host])) == length(var.nodes)
    error_message = "Two nodes share the same host number."
  }
}
