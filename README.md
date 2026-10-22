# Vigil infrastructure

Everything needed to build, deploy and operate [`vigil`](../vigil), a self-hosted uptime monitor: the CI server,
virtual machines, Kubernetes, GitOps and monitoring. Application code lives in the app repo; this repo describes
where and how it runs.

## Target architecture

```
 git push ─▶ Jenkins ─▶ tests ─▶ SonarQube ─▶ image ─▶ Trivy ─▶ GHCR
                                                        │
                        bumps image tag in this repo ◀──┘
                                   │
                                ArgoCD ─▶ k3s cluster (VMs from Terraform, configured by Ansible)
                                            ├─ api, worker (Helm chart)
                                            ├─ postgres, redis
                                            └─ Prometheus, Grafana, Loki
```

GitHub Actions in the app repo stays as the fast check on every pull request; Jenkins runs the full pipeline and is
the only system that publishes images.

## Layout

| Folder | Contents | Status |
|--------|----------|--------|
| `ci/` | Jenkins and SonarQube on Docker Compose, Jenkins configuration | In progress |
| `terraform/` | VMs on local KVM (libvirt provider), later the cloud | Planned |
| `ansible/` | VM hardening and k3s install | Planned |
| `helm/` | The `vigil` Helm chart | Planned |
| `argocd/` | ArgoCD Application definitions | Planned |
| `monitoring/` | Prometheus rules, Grafana dashboards, alerting | Planned |

Each folder gets its own README with how to run it once it exists.

## Rules for this repo

- No secrets in git: passwords, tokens and keys come from environment variables, `.env` files (ignored), Jenkins
  credentials or, from week 6, encrypted secrets.
- No generated state in git: Terraform state, kubeconfigs and Jenkins home stay out of the repo.
- Every change to running infrastructure goes through this repo, so the repo always describes what is deployed.
