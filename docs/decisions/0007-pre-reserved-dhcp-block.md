# 0007: Pre-reserved DHCP block instead of one reservation per node

- **Status:** Accepted (supersedes the reservation list in [0002](0002-network-and-addressing.md))
- **Date:** 2026-11-17

## Context

[0002](0002-network-and-addressing.md) built the network's DHCP reservations from the node map, one per node. In the
libvirt provider 0.9.9, reservations live inside the network's `ips` block, and any change to `ips` forces the
network to be **replaced**. The provider has no separate reservation resource, although libvirt itself can add one
to a live network (`virsh net-update`).

So adding or removing a node recreated the network. libvirt deletes the bridge, and the VMs that stay are not
replaced, so they keep running with their network card attached to nothing until restarted. Adding a k3s agent
would have cut off the control plane. The first full plan of Step 3 showed `libvirt_network.vigil must be
replaced`, which is how this was found.

## Options

1. **Pre-reserve a fixed block of host numbers.** MACs are derived from the host number, so a reservation can exist
   before its VM. The network depends only on the block, never on the node map.
2. **Static IPs through cloud-init** (option 2 of 0002): no reservations at all. Rejected again for the same reason
   as in 0002: the addressing is spread across the VMs.
3. **Accept it:** every change to the node set means rebuilding the whole cluster. Rejected: no adding a node to a
   live cluster.

## Decision

Option 1 with a block of 20: host numbers 10–29 (`10.77.0.10`–`10.77.0.29`), set in `locals.tf`
(`reserved_first`, `reserved_count`).

- Each reserved number N maps MAC `52:54:00:77:00:<N in hex>` to `10.77.0.N`, the same formula the nodes use.
- Reservations carry no host name. DNS names (`vigil-agent-1.vigil.internal`) come from the hostname each VM sends
  in its DHCP request, which Ubuntu does by default.
- A precondition on the network rejects, at plan time, any node whose host number is outside the block.

20 is far more than this laptop can run (about 4 nodes). Reserving the whole /24 was considered and not needed.

## Consequences

- Adding or removing a node touches only that node's resources. Checked on 2026-11-17: removing and re-adding
  `vigil-agent-2` while pinging `vigil-server` lost 0 packets, and the plans never listed the network.
- A node outside the block fails at `tofu plan`, before anything changes. Nothing is half-applied.
- Growing or moving the block, or changing `network_cidr`, still replaces the network: a planned maintenance
  step (restart or rebuild the VMs), never a side effect of adding a node.
- The network holds reservations for VMs that do not exist yet. They are harmless.
- General lesson: before trusting a plan, look for `must be replaced` on shared resources (networks, pools,
  disks), not only on the resource being changed.
