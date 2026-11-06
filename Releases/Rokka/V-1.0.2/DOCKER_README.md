<div align="center">

<img src="https://raw.githubusercontent.com/aarkamio/Aarkam/main/docs/images/aarkam-logo.png" alt="Aarkam Logo" width="180" />

# Rokka Sovereign Storage Engine & Distributed Fabric
### High-Performance Stateless Control Plane, Raft Consensus Quorum & Line-Rate S3 Streaming Gateway

[![Version](https://img.shields.io/badge/version-v1.0.2--GA-blue.svg?style=for-the-badge&logo=semver)](https://github.com/Aarkam-IO/Aarkam.Rokka)
[![Docker Image](https://img.shields.io/badge/docker-aarkam%2Faarkam.rokka-2496ED.svg?style=for-the-badge&logo=docker)](https://hub.docker.com/r/aarkam/aarkam.rokka)
[![Target OS](https://img.shields.io/badge/platform-Linux%20x64%20%7C%20Windows%20x64-333333.svg?style=for-the-badge&logo=linux)](https://github.com/Aarkam-IO/Aarkam.Rokka)
[![Architecture](https://img.shields.io/badge/arch-x86__64%20(AVX2%20%2F%20AVX--512)-orange.svg?style=for-the-badge)](https://github.com/Aarkam-IO/Aarkam.Rokka)
[![Compliance](https://img.shields.io/badge/compliance-NCA%20ECC--2%3A2024%20%7C%20FIPS%20140--3-darkgreen.svg?style=for-the-badge)](https://github.com/Aarkam-IO/Aarkam.Rokka)
[![Air-Gapped](https://img.shields.io/badge/network-100%25%20Air--Gapped%20Zero--Egress-critical.svg?style=for-the-badge)](https://github.com/Aarkam-IO/Aarkam.Rokka)

</div>

---

## 1. What is Rokka?

**Rokka Sovereign Storage Engine** is the autonomous, zero-cloud data plane and control plane of the **Aarkam Sovereign Storage Ecosystem**. Engineered for strict air-gapped sovereign environments, Rokka combines:

1. **`rokka-coordinator`**: Stateless control plane, Raft consensus quorum, dynamic Highest Random Weight (HRW / Rendezvous) node placement, and mTLS Node Enrollment Certificate Authority (`EnrollNode`).
2. **`rokka-gateway`**: Streaming S3 SigV4 compatible REST gateway, SIMD-accelerated Cauchy Reed-Solomon erasure coding, client-side AES-256-GCM envelope encryption, and speculative hedged download pipelines.

Rokka operates with complete autonomy—requiring zero external database dependencies, zero third-party cloud callbacks, and zero external runtime frameworks.

---

## 2. Core Architectural Capabilities

### 2.1 Autonomous Substrate Decoupling
- **Zero Monolithic Coupling**: Decoupled from bundled node daemons. Rokka communicates with Abodi storage nodes strictly over high-performance HTTP/2 gRPC (Port 7775 / 57775) and zero-copy RDMA verbs.
- **Standalone Single-File Binaries**: Compiled as self-contained executables with embedded .NET 10.0 runtime. Requires zero pre-installed runtime dependencies.

### 2.2 Ahmodi SIMD Cauchy Reed-Solomon Erasure Coding
- **Galois Field $\text{GF}(2^8)$ SIMD Kernels**: AVX2 and AVX-512 hardware-accelerated Cauchy erasure coding supporting standard **4+2**, **8+3**, and **16+4** stripe profiles.
- **Silent Bitrot Self-Healing**: Transparently detects Castagnoli CRC32 mismatches on disk, discards corrupted chunks, fetches parity chunks, and mathematically reconstructs exact bit-for-bit payloads on-the-fly.

### 2.3 Sovereign AWS SigV4 S3 Gateway
- **Line-Rate S3 Compatibility**: Implements standard S3 REST endpoints (`PutObject`, `GetObject`, `DeleteObject`, `HeadObject`, `ListObjectsV2`, `CreateBucket`, `DeleteBucket`).
- **Client-Side Envelope Encryption**: AES-256-GCM authenticated encryption derives unique per-chunk cryptographic keys, ensuring zero plaintext chunks ever touch disk unencrypted.
- **Speculative Hedged Download Pipeline**: Adaptive hedge requests dispatched after configurable thresholds eliminate tail latency across distributed storage nodes.

### 2.4 Ceph-Class Raft Consensus & Fencing
- **Monotonic Epoch Fencing**: Enforces two-phase epoch advancement preventing stale partitioned nodes from accepting writes after quorum topology changes.
- **Automated Policy Transcoding**: Background worker transcodes legacy replica chunks into Cauchy erasure stripes at bounded line rates.

---

## 3. Prerequisites & Storage Fabric (Abodi)

Before deploying the Rokka container substrate, verify that your environment satisfies the following architectural and sizing prerequisites:

### 3.1 Physical Storage Nodes: Aarkam Abodi Daemon
Rokka operates as the **Stateless Control Plane** (`rokka-coordinator`) and **Line-Rate S3 Streaming Gateway** (`rokka-gateway`). Rokka **does not store raw disk blocks itself**; erasure chunks are streamed directly across physical storage nodes hosting the **Aarkam Abodi Storage Node Daemon**:

* **Official Docker Hub Image**: [**`aarkam/aarkam.abodi`**](https://hub.docker.com/r/aarkam/aarkam.abodi) (`https://hub.docker.com/r/aarkam/aarkam.abodi`)
* **Role**: Runs on bare-metal or containerized storage hosts alongside hardware drives, executing direct sector-aligned I/O (`O_DIRECT`), hosting the Kdouja PageStore, and streaming real-time hardware vitals, NVMe SMART telemetry, and predictive Weibull health scoring to the Rokka Coordinator.
* **Cluster Minimum**: For standard **4+2** Cauchy Reed-Solomon erasure coding, a minimum of **6 independent Abodi storage nodes** is required to guarantee strict failure-domain survival.

### 3.2 Cryptographic Keys & Zero-Trust Credentials
In accordance with Saudi NCA ECC-2:2024 (§2-1-3) and FIPS 140-3 Zero-Trust requirements, passphrases and encryption keys **must never be stored in static configuration files**:
* **`ROKKA_CLUSTER_CA_PASSWORD`**: Strong passphrase securing the cluster mTLS Root CA certificate (`ca.pfx`). Must be supplied via environment variable or secret mount (`$CREDENTIALS_DIRECTORY/rokka_ca_password` or `/run/secrets/rokka_ca_password`).
* **`ROKKA_MASTER_KEY`**: 64-character hexadecimal AES-256 master cryptographic key used for per-chunk envelope key derivation.
* **`ROKKA_WAL_ENCRYPTION_KEY`**: 64-character hexadecimal key used to encrypt in-process KdoujaKV metadata write-ahead logs.

### 3.3 Host System & Compute Requirements
* **Architecture**: `x86_64` (AMD64) CPU with **AVX2** (or **AVX-512** for line-rate $\text{GF}(2^8)$ Galois Field Cauchy erasure matrix performance).
* **Docker Engine**: Docker 24.0+ or Docker Desktop 4.25+ with Docker Compose v2.
* **Networking**: Ports `7774`/`57774` (Coordinator) and `7772`/`57772` (Gateway), with bidirectional network routing to Abodi nodes on ports `7775`/`57775`.

---

## 4. Container Image Tags & Architecture

| Tag | Architecture | Base OS | Description |
| :--- | :--- | :--- | :--- |
| **`v1.0.2`**, **`1.0.2`**, **`latest`** | `linux/amd64` (x86_64, AVX2) | Ubuntu 24.04 LTS Noble (`dotnet/aspnet:10.0`) | Official Production Release with embedded Coordinator, Gateway, and health monitoring. |

---

## 5. Docker Quick Start

### 5.1 Running via Docker CLI

```bash
docker run -d \
  --name rokka-substrate \
  -p 7774:7774 \
  -p 57774:57774 \
  -p 7772:7772 \
  -p 57772:57772 \
  -v rokka_metadata:/var/lib/rokka/metadata \
  -v rokka_data:/var/lib/rokka/data \
  -e ROKKA_ROLE=all \
  -e ROKKA_CLUSTER_CA_PASSWORD=AARKAM_SOVEREIGN_CA_SECRET_PASSPHRASE \
  -e ROKKA_MASTER_KEY=AARKAM_SOVEREIGN_MASTER_KEY_SECRET \
  -e ROKKA_WAL_ENCRYPTION_KEY=AARKAM_SOVEREIGN_WAL_SECRET_KEY \
  aarkam/aarkam.rokka:v1.0.2
```

### 5.2 Running via Docker Compose

```yaml
services:
  rokka:
    image: aarkam/aarkam.rokka:v1.0.2
    container_name: rokka-substrate
    restart: unless-stopped
    ports:
      - "7774:7774"     # Coordinator HTTP
      - "57774:57774"   # Coordinator HTTPS
      - "7772:7772"     # Gateway HTTP (S3)
      - "57772:57772"   # Gateway HTTPS (S3)
    volumes:
      - rokka_metadata:/var/lib/rokka/metadata
      - rokka_data:/var/lib/rokka/data
      - rokka_logs:/var/log/rokka
      - rokka_config:/etc/rokka
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      - DOTNET_CLI_TELEMETRY_OPTOUT=1
      - ROKKA_ROLE=all
      - ROKKA_CLUSTER_CA_PASSWORD=AARKAM_SOVEREIGN_CA_SECRET_PASSPHRASE
      - ROKKA_MASTER_KEY=AARKAM_SOVEREIGN_MASTER_KEY_SECRET
      - ROKKA_WAL_ENCRYPTION_KEY=AARKAM_SOVEREIGN_WAL_SECRET_KEY

volumes:
  rokka_metadata:
  rokka_data:
  rokka_logs:
  rokka_config:
```

---

## 6. Port Topology

| Port | Protocol | Encryption | Role | Description |
| :--- | :--- | :--- | :--- | :--- |
| **7774** | HTTP/1.1 | Cleartext | Coordinator | Health check (`/health`), Prometheus metrics (`/metrics`) |
| **57774** | HTTP/2 | mTLS | Coordinator | Raft consensus, node enrollment CA, and topology sync |
| **7772** | HTTP/1.1 | Cleartext | Gateway | Standard S3 REST endpoints (`PutObject`, `GetObject`) |
| **57772** | HTTP/1.1 & 2 | TLS | Gateway | Secure SigV4 S3 REST endpoint |

---

## 7. Health Checks & Verification

Verify the running container:

```bash
# Check Coordinator health
curl -f http://127.0.0.1:7774/health

# Check Gateway health
curl -f http://127.0.0.1:7772/health
```

---

Proprietary — Copyright © 2026 Aarkam.IO. All rights reserved.
