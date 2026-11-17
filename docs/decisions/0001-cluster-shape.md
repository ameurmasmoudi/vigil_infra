# 0001: Cluster shape

- **Status:** Accepted
- **Date:** 2026-11-17

## Context

Vigil (api, worker, Postgres, Redis, later a monitoring stack) runs on a k3s cluster built on KVM VMs on a single
machine with 15 GB of RAM. The cluster exists to run Vigil and to practise how Kubernetes behaves across machines:
scheduling, node drains, node failures and node-bound storage.

Kubernetes splits a cluster into a control plane (API server, scheduler, controllers, datastore) and workers that run
the containers. k3s calls them server and agent. By default a k3s server also runs application pods.

## Options

1. **Single node** (server and worker on one VM): cheapest, but nothing to schedule between and nothing to fail
   over to.
2. **1 server + 2 agents, server also runs pods:** uses the server's spare memory, but an application that exhausts
   memory can get the control plane killed.
3. **1 server + 2 agents, server tainted `NoSchedule`:** applications only run on agents. Two agents is the minimum
   for "a machine dies and the application survives".
4. **3 servers (HA control plane) + agents:** survives losing a server, but does not fit in the RAM budget.

## Decision

Option 3.

| Node | Role | vCPU | RAM | Disk |
|------|------|------|-----|------|
| `vigil-server` | k3s server, tainted | 2 | 2 GB | 20 GB |
| `vigil-agent-1` | k3s agent | 2 | 3 GB | 20 GB |
| `vigil-agent-2` | k3s agent | 2 | 3 GB | 20 GB |

## Consequences

- At most 8 GB of RAM (KVM only backs memory the guests touch); the CI stack must be stopped while the cluster runs.
- The server's spare memory (about 1 GB) is unused by applications.
- Single control plane: if `vigil-server` is down, running pods keep serving but nothing can be changed or
  rescheduled. Accepted for a lab; the k3s datastore choice (Step 6) should keep the door open to more servers.
- Node-local storage ties Postgres to one agent, which week 4 has to address.
