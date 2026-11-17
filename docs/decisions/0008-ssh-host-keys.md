# 0008: SSH host keys: trust on first use, in a cluster-only file

- **Status:** Accepted
- **Date:** 2026-11-17

## Context

Each VM generates new SSH host keys at first boot. SSH uses the host key to prove a machine is the one it talked to
before, which is what stops a man-in-the-middle. After a rebuild the same IP answers with a different key and SSH
refuses to connect ("REMOTE HOST IDENTIFICATION HAS CHANGED"). The VMs are rebuilt often, so Ansible needs a
policy.

## Options

1. **Turn checking off** (`host_key_checking = False`, known hosts sent to `/dev/null`): never complains, but
   accepts any key from anyone, every time. The protection is gone.
2. **Trust on first use in a dedicated file** (`StrictHostKeyChecking=accept-new`,
   `UserKnownHostsFile=.known_hosts` in `ansible/`): an unknown host's key is saved at first contact; a key that
   differs from the saved one is refused. Rebuilt nodes need their entries removed.
3. **Keys known in advance:** OpenTofu generates each VM's host key (`tls` provider), cloud-init installs it and
   OpenTofu writes the matching known hosts file. No first-contact trust at all, but two more providers, and the
   VMs' private host keys in the OpenTofu state.

## Decision

Option 2, set in `ansible/ansible.cfg` (`host_key_checking = True` plus the two SSH options). The file is gitignored
and separate from `~/.ssh/known_hosts`, so cluster churn never touches the user's own trusted hosts.

## Consequences

- A changed key is still refused. Checked on 2026-11-17: after rebuilding `vigil-agent-2`, Ansible failed with
  "REMOTE HOST IDENTIFICATION HAS CHANGED" until the old entry was removed.
- The first connection trusts whatever answers. On a NAT network that exists only on this laptop, nothing else can
  answer there.
- After a rebuild: `rm .known_hosts` (whole cluster) or `ssh-keygen -f .known_hosts -R <ip>` (one node). Step 7
  adds this to the rebuild command.
- Commands must run from `ansible/`: that is where Ansible finds `ansible.cfg`, and the file path is relative.
- Option 3 is the upgrade path if the network ever stops being private to one machine.
