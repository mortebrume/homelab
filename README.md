# Homelab

This repository defines my **personal homelab infrastructure**, managed using the **GitOps** pattern with [FluxCD](https://fluxcd.io/). It is a space to document and iterate on a Kubernetes-based **self-hosted** environment, with the goal of gaining hands-on experience in **DevOps**, networking, and infrastructure automation.

---

## Overview

The project is in its **initial documentation and design phase**. I'm currently selecting and testing technologies before provisioning the first cluster.

### Cluster Layout

- **[`brume`](./clusters/brume/)**  
  A *single-node, public-facing* cluster running on a dedicated server. Initially managed with *Docker Compose*, it will be migrated to [K3s](https://k3s.io/). This cluster uses the `mortebrume.eu` domain.

- **[`clade`](./clusters/clade/)**  
  A *multi-node test cluster* on virtual machines, intended for experimentation and staging. It will likely be exposed under a subdomain (e.g., `clade.mortebrume.eu`). [Talos](https://www.talos.dev/) is under consideration as the operating system for this cluster.

---

## Technology Stack

- **Kubernetes Distribution**  
  [K3s](https://k3s.io/) for both clusters. [Talos](https://talos.dev/) is being evaluated for *clade*.

- **GitOps Management**  
  [FluxCD](https://fluxcd.io/) manages cluster resources declaratively.

- **Ingress & API Gateway**  
  [Envoy Gateway](https://gateway.envoyproxy.io/), implementing the [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/).

- **Certificate Management**  
  [cert-manager](https://cert-manager.io/) is used to manage TLS certificates automatically via ACME.

- **DNS Management**  
  [ExternalDNS](https://github.com/kubernetes-sigs/external-dns) is considered to dynamically manage DNS records. Alternatives like wildcard DNS are currently in use for development.

- **CNI (Container Network Interface)**  
  - *brume*: [Flannel](https://github.com/flannel-io/flannel) for simplicity.
  - *clade*: Open to testing [Cilium](https://cilium.io/).

- **Storage**  
  - *brume*: Local path provisioner built into k3s.
  - *clade*: Potential use of [Longhorn](https://longhorn.io/) for distributed storage.

- **Secret Management**  
  [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) is used to encrypt and safely store Kubernetes secrets in Git.

- **Metrics and Logging**  
  A lightweight monitoring stack is planned, likely using the [VictoriaMetrics](https://victoriametrics.com/) suite :
  - [VictoriaMetrics](https://victoriametrics.com/) for metrics.
  - [VictoriaLogs](https://victoriametrics.com/products/victorialogs/) for log aggregation.

- **Automated Dependency Updates**  
  [Renovate](https://docs.renovatebot.com/) will be integrated to keep the stack updated and secure.

---

## Goals

### Short-Term Goals

- Study and document Kubernetes *networking fundamentals* (e.g., Cilium, Calico).
- Finalize decisions around OS, storage, and CNI for *clade*.
- Provision *clade* as the initial experimental Kubernetes environment.
- Implement **GitOps**, TLS management, and **DNS automation** using the tools above.
- Transition *brume* from **Docker Compose** to a GitOps-managed **K3s** cluster.

### Long-Term Goals

- Define **reusable CRDs** for common self-hosted services using [Yoke](https://yokecd.github.io/).
- Build a **multi-node** cluster using mini-PCs across different physical networks.
- Deepen experience with distributed storage, observability, and multi-cluster operations.
