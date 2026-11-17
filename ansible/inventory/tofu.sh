#!/usr/bin/env bash
set -euo pipefail

tf_dir="$(cd "$(dirname "$0")/../../terraform" && pwd)"

case "${1:-}" in
  --list) ;;
  --host) echo '{}'; exit 0 ;;
  *) echo "usage: $0 --list | --host <name>" >&2; exit 2 ;;
esac

outputs=$(tofu -chdir="$tf_dir" output -json)

if [[ $(jq '.nodes.value // {} | length' <<<"$outputs") -eq 0 ]]; then
  echo "No nodes in OpenTofu outputs: run 'tofu apply' in $tf_dir first." >&2
  exit 1
fi

jq '
  .ssh_user.value as $user
  | .nodes.value as $nodes
  | {
      _meta: {
        hostvars: ($nodes | with_entries(.value = {ansible_host: .value.ip, node_ip: .value.ip}))
      },
      all: {
        vars: { ansible_user: $user },
        children: ["server", "agents"]
      },
      server: { hosts: [$nodes | to_entries[] | select(.value.role == "server") | .key] },
      agents: { hosts: [$nodes | to_entries[] | select(.value.role == "agent") | .key] }
    }
' <<<"$outputs"
