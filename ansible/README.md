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

## Files

| File | Contents |
|------|----------|
| `ansible.cfg` | Inventory script, SSH key `~/.ssh/vigil`, Python found automatically, host key policy |
| `requirements.yml` | Pinned collections (`community.general` for `timezone`) |
| `base.yml` | Base configuration for every node: apt cache, a few tools, UTC, login banner |
| `templates/motd.j2` | The login banner, filled from inventory variables (name, group, IP) |

## Usage

Run everything from this folder: Ansible reads `ansible.cfg` from the current directory.

```sh
ansible-galaxy collection install -r requirements.yml   # once
ansible all -m ping                                     # SSH + Python work on every node
ansible-playbook base.yml --check --diff                # dry run: what would change
ansible-playbook base.yml                               # apply; a second run must report changed=0
```

## Host keys

Every rebuild gives the VMs new SSH host keys. Keys are trusted on first contact and saved in `.known_hosts`
(gitignored, separate from `~/.ssh/known_hosts`); a key that changes later is refused. After rebuilding, remove the
old entries: `rm .known_hosts`, or `ssh-keygen -f .known_hosts -R 10.77.0.12` for one node.
Why: [SSH host keys](../docs/decisions/0008-ssh-host-keys.md).
