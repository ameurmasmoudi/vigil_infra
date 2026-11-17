# 0005: Dynamic inventory from OpenTofu outputs

- **Status:** Accepted
- **Date:** 2026-11-17

## Context

Ansible needs an inventory (which hosts exist, their addresses, their groups). OpenTofu already knows this because
it created the VMs. A hand-written inventory drifts the first time a node is added in one tool and not the other.

## Options

1. **OpenTofu writes an inventory file** (`local_file` + template) at every apply: common and easy to inspect;
   needs the `hashicorp/local` provider; the file is a snapshot.
2. **Dynamic inventory script:** Ansible runs a script that reads `tofu output -json` every time.
3. **Ansible inventory plugin for Terraform state** (`cloud.terraform` collection): reads the state directly;
   another collection to install and depends on the state's internal format.

## Decision

Option 2: `ansible/inventory/tofu.sh`.

- OpenTofu exposes a `nodes` output (`name => {role, ip}`) and `ssh_user`; the outputs are the contract between the
  two tools, not the state file.
- The script turns them into Ansible's JSON: groups `server` and `agents` (from each node's role), `ansible_host`
  and `node_ip` per host, `ansible_user` for all. `_meta.hostvars` is included so Ansible calls it once, not once
  per host.
- It fails with a clear message if there are no nodes (nothing applied yet).

## Consequences

- The inventory cannot be stale and nothing extra is installed.
- Every Ansible run needs `tofu` and access to the state, so Ansible runs where OpenTofu does (here, the same
  machine). With a remote backend this would still work from anywhere with state access.
- Requires `jq`.
