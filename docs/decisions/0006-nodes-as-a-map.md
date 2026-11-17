# 0006: Nodes as one map with `for_each`

- **Status:** Accepted
- **Date:** 2026-11-17

## Context

Three VMs share the same resources (disk, cloud-init disk, domain) with different values. OpenTofu can repeat a
resource with `count` (a list, addressed by position: `node[0]`, `node[1]`) or `for_each` (a map, addressed by key:
`node["vigil-agent-1"]`).

## Decision

One variable `nodes`, a map from node name to `{role, vcpu, memory_mb, disk_gb, host}`, and `for_each` over it in
every per-node resource. IP and MAC are derived from `host` in `locals.tf`. Validation rules reject an unknown
role, zero or several servers, a host number outside 2–254 and duplicate host numbers.

## Consequences

- Removing `vigil-agent-1` destroys only that VM. With `count`, removing the middle element shifts the next one's
  index, so OpenTofu would destroy and recreate the VMs after it.
- Adding a node is one map entry; the network reservation, the outputs and the inventory follow automatically.
- The defaults in `variables.tf` describe this cluster, so no `.tfvars` file is needed. A local `terraform.tfvars`
  (gitignored) can override them, for example smaller VMs on a machine with less RAM.
