# Decision records

One file per significant design decision: the context, the options considered, what was chosen and what it costs.
A decision that changes later gets a new record that supersedes the old one, so the history stays readable.

| # | Decision | Status |
|---|----------|--------|
| [0001](0001-cluster-shape.md) | Cluster shape: 1 tainted k3s server + 2 agents | Accepted |
| [0002](0002-network-and-addressing.md) | Dedicated NAT network, fixed IPs through DHCP reservations | Accepted, reservations superseded by 0007 |
| [0003](0003-base-image-pinning.md) | Pinned Ubuntu 24.04 cloud image, verified by checksum before use | Accepted |
| [0004](0004-opentofu-and-libvirt-provider.md) | OpenTofu with the libvirt provider pinned to 0.9.9 | Accepted |
| [0005](0005-dynamic-inventory.md) | Ansible inventory read from OpenTofu outputs at run time | Accepted |
| [0006](0006-nodes-as-a-map.md) | Nodes defined as one map, created with `for_each` | Accepted |
| [0007](0007-pre-reserved-dhcp-block.md) | Pre-reserved DHCP block (hosts 10–29), so node changes never replace the network | Accepted |
