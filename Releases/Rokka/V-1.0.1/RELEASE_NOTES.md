# Rokka Sovereign Storage Engine & Distributed Fabric
# Official Production Release Notes (Version 1.0.1-GA)

| Release Metadata | Specification |
| :--- | :--- |
| **Product** | Rokka Sovereign Storage Engine & Distributed Control Plane |
| **Release Version** | `v1.0.1-GA (General Availability)` |
| **Release Date** | November 2026 |
| **Architectural Role** | Autonomous Sovereign Storage Data Plane & Control Plane |
| **Dependency Scope** | Core Substrate for **Aarkam - SAT (Standalone Tier)** & **Aarkam - SCT (Storage Centers Tier)** |
| **Compliance Level** | Saudi NCA ECC-2:2024, NCA CSCC-1:2023, FIPS 140-3 Zero-Trust Architecture |
| **Target Distribution** | Zero-Egress Air-Gapped Datacenters (Linux x64, Windows Server x64, OCI Container) |

---

## 1. Executive Summary

**Rokka v1.0.1-GA** marks the milestone release establishing full OCI containerization, Docker Hub automated publishing via GitHub Actions, enhanced health probes, and complete parity with the **Abodi** node agent lifecycle.

As the distributed data fabric and stateless control plane of the Aarkam ecosystem, **Rokka provides**:
1. **`rokka-coordinator`**: Stateless control plane, Raft MON consensus quorum, dynamic Highest Random Weight (HRW / Rendezvous) node placement, and mTLS Node Enrollment Certificate Authority (`EnrollNode`).
2. **`rokka-gateway`**: Streaming S3 SigV4 compatible REST gateway, SIMD-accelerated Cauchy Reed-Solomon erasure coding, client-side AES-256-GCM envelope encryption, and speculative hedged download pipelines.

Version 1.0.1-GA delivers complete autonomous operation in 100% disconnected, zero-egress air-gapped environments without external database dependencies or runtime prerequisites.

---

## 2. What's New in Version 1.0.1-GA

### 2.1 Automated GitHub Actions & Docker Hub Distribution
- **Automated Multi-Tag Container Publishing**: Implemented `.github/workflows/docker-publish.yml` triggering on GitHub Releases and manual dispatch to build and push verified images directly to Docker Hub:
  - `aarkam/aarkam.rokka:v1.0.1`
  - `aarkam/aarkam.rokka:1.0.1`
  - `aarkam/aarkam.rokka:latest`
- **Hardened Multi-Daemon Container Runtime (`Dockerfile.release`)**: Built on Ubuntu 24.04 LTS Noble (`dotnet/aspnet:10.0-noble`), bundling curl, iproute2, and diagnostic utilities with non-root capability isolation and explicit volume mount points.
- **Dynamic Role Entrypoint (`entrypoint.sh`)**: Supports running Coordinator (`ROKKA_ROLE=coordinator`), Gateway (`ROKKA_ROLE=gateway`), or both daemons simultaneously (`ROKKA_ROLE=all`).

### 2.2 Standardized Health Probe & Observability Endpoints
- **Coordinator HTTP Health Probe (`/health`)**: Added dedicated `GET /health` endpoint on port `7774` returning instantaneous node health status alongside existing Prometheus metrics at `/metrics`.
- **Gateway S3 & Ingestion Health Probes**: Validated line-rate health checks on port `7772` (`/health` and `/api/v1/cluster/health`).

### 2.3 Standalone Substrate Decoupling
- **Decoupled Architecture**: Rokka daemons operate completely standalone. Storage node communication with Abodi occurs exclusively over authenticated HTTP/2 gRPC (port `57775`) and zero-copy RDMA verbs.
- **Embedded Kdouja KV Kernel**: Retains high-speed zero-dependency in-process metadata storage (`KdoujaKV`) for Raft consensus log durability and S3 object catalogs.

---

## 3. Package & Distribution Matrix

| Artifact Name | Target Architecture | Contents | Distribution Channel |
| :--- | :--- | :--- | :--- |
| **`rokka-v1.0.1-linux-x64.zip`** | Linux x64 (glibc 2.31+) | Single-file `rokka-coordinator`, `rokka-gateway`, `install-rokka.sh`, settings | [GitHub Releases](https://github.com/Aarkam-IO/Aarkam.Rokka/releases) |
| **`rokka-v1.0.1-win-x64.zip`** | Windows Server x64 (2022/2025) | Single-file `rokka-coordinator.exe`, `rokka-gateway.exe`, `install-rokka.ps1` | [GitHub Releases](https://github.com/Aarkam-IO/Aarkam.Rokka/releases) |
| **`aarkam/aarkam.rokka:v1.0.1`** | OCI Container (Linux x64) | Production-hardened container image with embedded daemons and entrypoint | [Docker Hub Repository](https://hub.docker.com/r/aarkam/aarkam.rokka) |

---

## 4. Quick Start: Docker Hub

Pull and run the official container:

```bash
# Pull official image
docker pull aarkam/aarkam.rokka:v1.0.1

# Run Coordinator and Gateway in unified container
docker run -d \
  --name rokka-node \
  -p 7774:7774 \
  -p 57774:57774 \
  -p 7772:7772 \
  -p 57772:57772 \
  -v rokka_metadata:/var/lib/rokka/metadata \
  -v rokka_data:/var/lib/rokka/data \
  -e ROKKA_ROLE=all \
  aarkam/aarkam.rokka:v1.0.1
```

Or deploy with Docker Compose:

```bash
docker compose up -d
```

---

## 5. Network Port Topology

| Port | Protocol | Encryption | Subsystem | Description |
| :--- | :--- | :--- | :--- | :--- |
| **7774** | HTTP/1.1 | Cleartext | Coordinator | Local Health Probe (`/health`), Prometheus Metrics (`/metrics`) |
| **57774** | HTTP/2 | mTLS | Coordinator | Cluster Raft MON Consensus, Node Enrollment CA, Topology Epochs |
| **7772** | HTTP/1.1 | Cleartext | Gateway | Standard S3 REST Storage API & Streaming Ingestion |
| **57772** | HTTP/1.1 & 2 | TLS | Gateway | Secure S3 REST Gateway (AWS SigV4 Authenticated) |

---

Proprietary — Copyright © 2026 Aarkam.IO. All rights reserved.
