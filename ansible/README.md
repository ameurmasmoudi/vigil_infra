# Vigil cluster: configuration

Ansible configures the VMs created by [`../terraform/`](../terraform/README.md): hardening, then k3s.

## Inventory

There is no hand-written inventory. `inventory/tofu.sh` reads `tofu output -json` from `../terraform` on every run
and gives Ansible:

| Group | Hosts |
|-------|-------|
| `server` | the node with role `server` (`vigil-server`) |
| `agents` | the nodes with role `agent` (`vigil-agent-1`, `vigil-agent-2`) |

Each host gets `ansible_host` and `node_ip` (its IP); all hosts get `ansible_user` from OpenTofu's `ssh_user`.
Why: [dynamic inventory](../docs/decisions/0005-dynamic-inventory.md).

```sh
ansible-inventory -i inventory/tofu.sh --graph
```

Requirements: `tofu` and `jq`, and an applied OpenTofu configuration (the script fails clearly otherwise).
