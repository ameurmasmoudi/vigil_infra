# 0002: Network and addressing

- **Status:** Accepted; the reservation list is superseded by [0007](0007-pre-reserved-dhcp-block.md)
- **Date:** 2026-11-17

## Context

Three things record node addresses: the Ansible inventory, the k3s agents' join URL (`https://<server>:6443`) and
the kubeconfig. VMs are destroyed and recreated often, so each node needs the same address after every rebuild.
libvirt's existing `default` network is shared, managed outside this repository and hands out its whole range by
DHCP.

## Options

1. **`default` network, plain DHCP:** no code, but addresses can change after a rebuild.
2. **Own network, static IPs written into each VM by cloud-init:** stable, but every VM needs its own network
   configuration and the addressing is spread across them.
3. **Own network, DHCP reservations:** OpenTofu gives each VM a fixed MAC address and the network maps each MAC to
   an IP. Every VM just asks DHCP.

## Decision

Option 3, on a dedicated NAT network `vigil`, `10.77.0.0/24`, created by OpenTofu:

- Gateway and DNS (libvirt's dnsmasq): `10.77.0.1`; DNS domain `vigil.internal`.
- Node `host` number N gives IP `10.77.0.N` and MAC `52:54:00:77:00:<N in hex>` (`52:54:00` is the prefix
  reserved for QEMU/KVM virtual cards). Server `.10`, agents `.11` and `.12`.
- No dynamic range: only reserved MACs get an address.

The range avoids k3s's pod (`10.42.0.0/16`) and service (`10.43.0.0/16`) networks and the 172.x/192.168.x ranges
Docker uses on the host.

## Consequences

- The addressing plan lives in one place (the node map); network and VMs read the same values and cannot disagree.
- Every VM's network configuration is identical. This is also how clouds deliver "fixed" private IPs.
- `tofu destroy` removes the network with everything else; nothing outside the repository is touched.
- Addresses depend on dnsmasq answering. If it is down, DNS is down too, so a static configuration would not help.
- NAT: VMs reach the internet, nothing outside the host reaches them.
