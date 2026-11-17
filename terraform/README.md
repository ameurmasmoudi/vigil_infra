# Vigil cluster: VMs

OpenTofu creates the VMs the k3s cluster runs on, using libvirt (KVM) on the local machine. Ansible configures them
afterwards (see [`../ansible/`](../ansible/README.md)).

## Cluster

| Node | Role | vCPU | RAM | Disk | IP |
|------|------|------|-----|------|----|
| `vigil-server` | k3s server (control plane), tainted `NoSchedule` | 2 | 2 GB | 20 GB | `10.77.0.10` |
| `vigil-agent-1` | k3s agent, runs workloads | 2 | 3 GB | 20 GB | `10.77.0.11` |
| `vigil-agent-2` | k3s agent, runs workloads | 2 | 3 GB | 20 GB | `10.77.0.12` |

All on the NAT network `vigil` (`10.77.0.0/24`, gateway and DNS `10.77.0.1`), Ubuntu 24.04 LTS, user `vigil` with
SSH key login only.

Why it looks like this:
[cluster shape](../docs/decisions/0001-cluster-shape.md),
[network and addressing](../docs/decisions/0002-network-and-addressing.md),
[base image](../docs/decisions/0003-base-image-pinning.md),
[OpenTofu and provider](../docs/decisions/0004-opentofu-and-libvirt-provider.md),
[nodes as a map](../docs/decisions/0006-nodes-as-a-map.md),
[pre-reserved DHCP block](../docs/decisions/0007-pre-reserved-dhcp-block.md).

## Files

| File | Contents |
|------|----------|
| `versions.tf` | OpenTofu and provider pins, libvirt connection (`qemu:///system`) |
| `variables.tf` | The node map, network range, SSH user and public key path, with validation |
| `locals.tf` | Derived values: each node's IP and MAC, the reserved DHCP block (hosts 10–29), the image pin |
| `network.tf` | The `vigil` NAT network, one DHCP reservation per host number in the block, a precondition that every node is inside it |
| `storage.tf` | The `vigil` storage pool and the base image volume (checksum precondition) |
| `nodes.tf` | Per node: overlay disk, cloud-init disk, VM |
| `outputs.tf` | `nodes` (name, role, IP) and `ssh_user`, read by the Ansible inventory |
| `cloud-init/` | First-boot user data (user, key, no password login) and network config (DHCP) |
| `image.json`, `fetch-image.sh` | The pinned cloud image and the script that downloads and verifies it |

## Usage

Requirements: libvirt with QEMU/KVM and dnsmasq, membership of the `libvirt` group, OpenTofu,
`jq`, and an SSH key at `~/.ssh/vigil` (`ssh-keygen -t ed25519 -f ~/.ssh/vigil`).

If the host runs a firewall with a default-drop policy (ufw here), the VMs cannot get an address or reach the
internet until traffic starting on their bridge is allowed. Rules match the bridge name, so they survive rebuilds:

```sh
sudo ufw allow in on virbr-vigil to any port 67 proto udp comment 'vigil VMs DHCP'
sudo ufw allow in on virbr-vigil to any port 53 comment 'vigil VMs DNS'
sudo ufw route allow in on virbr-vigil comment 'vigil VMs NAT + VM-to-VM'
```

The first two let the VMs reach libvirt's dnsmasq on the host and nothing else. The route rule allows forwarded
traffic that starts on the bridge: out to the internet through NAT, and between VMs (Docker loads `br_netfilter`, so
even same-bridge traffic goes through the firewall's FORWARD chain). Replies are already accepted as established
connections. Nothing outside can open a connection to the VMs.

```sh
./fetch-image.sh          # once per image release: download into ~/.cache/vigil/images and verify
tofu init
tofu apply
tofu output nodes
ssh -i ~/.ssh/vigil vigil@10.77.0.10
tofu destroy
```

A node's `host` must be between 10 and 29: those addresses are reserved in advance, so adding or removing a node
never touches the network. A number outside the block fails at `tofu plan`.

To change sizes or nodes locally without editing the defaults, put overrides in `terraform.tfvars` (gitignored).

## Never in git

State (`*.tfstate*`), `.terraform/`, local `*.tfvars`. `.terraform.lock.hcl` **is** committed: it pins provider
versions and checksums.
