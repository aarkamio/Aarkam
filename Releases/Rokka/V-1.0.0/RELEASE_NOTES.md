# Rokka Sovereign Storage Engine — Release Notes (Version V-1.0.0-GA)

| Specification | Standard |
| :--- | :--- |
| **Release Version** | `V-1.0.0-GA (Production General Availability)` |
| **Product** | Rokka Sovereign Storage Substrate |
| **Included Daemons** | `rokka-coordinator` & `rokka-gateway` |
| **Release Date** | October 2026 |
| **Compliance Standards** | Saudi NCA ECC-2:2024, NCA CSCC-1:2023, FIPS 140-3 Zero-Trust Architecture |
| **Target Platforms** | Linux x64 (glibc 2.31+), Windows Server x64 (2022/2025) |

---

## 1. Release Overview

**Rokka Sovereign Storage Engine V-1.0.0-GA** represents the official standalone production release of Aarkam's sovereign data plane and control plane.

In this release, Rokka is completely decoupled from the node agent (`Abodi`) and operator tool (`AM CLI`), producing an autonomous, zero-dependency sovereign storage engine composed strictly of:
1. **`rokka-coordinator`**: Stateless control plane, Raft consensus quorum, and Rendezvous HRW placement engine (Ports 7774 / 57774).
2. **`rokka-gateway`**: Streaming S3 SigV4 gateway, inline AES-256-GCM encryption, Ahmodi SIMD Cauchy Reed-Solomon erasure coding, and speculative hedged download pipeline (Ports 7772 / 57772).

---

## 2. Key Capabilities & Innovations

### 2.1 Autonomous Substrate Decoupling
- **Zero Monolithic Coupling**: Decoupled from bundled node daemons. Rokka communicates with Abodi storage nodes strictly over high-performance HTTP/2 gRPC (Port 7775 / 57775) and zero-copy RDMA verbs.
- **Standalone Single-File Binaries**: Compiled as self-contained executables with embedded .NET 10.0 runtime. Requires zero pre-installed runtime dependencies.

### 2.2 Ahmodi SIMD Cauchy Reed-Solomon Erasure Coding
- **Galois Field $\text{GF}(2^8)$ SIMD Kernels**: AVX2 and AVX-512 hardware-accelerated Cauchy erasure coding supporting standard **4+2**, **8+3**, and **16+4** stripe profiles.
- **Ordered Mathematical Submatrix Cache**: Thread-safe inverted submatrix caching ensures sub-microsecond reconstruction of lost chunks during concurrent degraded reads.
- **Silent Bitrot Self-Healing**: Transparently detects Castagnoli CRC32 mismatches on disk, discards corrupted chunks, fetches parity chunks, and mathematically reconstructs exact bit-for-bit payloads on-the-fly.

### 2.3 Sovereign AWS SigV4 S3 Gateway
- **Line-Rate S3 Compatibility**: Implements standard S3 REST endpoints (`PutObject`, `GetObject`, `DeleteObject`, `HeadObject`, `ListObjectsV2`, `CreateBucket`, `DeleteBucket`).
- **Client-Side Envelope Encryption**: AES-256-GCM authenticated encryption derives unique per-chunk cryptographic keys, ensuring zero plaintext chunks ever touch disk unencrypted.
- **Speculative Hedged Download Pipeline**: Adaptive hedge requests dispatched after configurable thresholds eliminate tail latency across distributed storage nodes.

### 2.4 Ceph-Class Raft Consensus & Fencing
- **Monotonic Epoch Fencing**: Enforces two-phase epoch advancement preventing stale partitioned nodes from accepting writes after quorum topology changes.
- **Automated Policy Transcoding**: Background worker transcodes legacy replica chunks into Cauchy erasure stripes at bounded line rates while preserving client I/O latency.

---

## 3. Breaking Changes & Upgrade Notes

- **Port Standardization**:
  - Coordinator default HTTP/2 gRPC port is `7774` (HTTPS on `57774`).
  - Gateway default HTTP S3 port is `7772` (HTTPS on `57772`).
- **Executable Renaming**:
  - Binaries are standardized as `rokka-coordinator` / `rokka-coordinator.exe` and `rokka-gateway` / `rokka-gateway.exe`.
- **Environment Invariants**:
  - `ROKKA_MASTER_KEY` is required by `rokka-gateway` (64-hex AES-256 master key).
  - `Rokka:WalEncryptionKey` is required by `rokka-coordinator` for metadata WAL encryption.

---

## 4. Verification & SHA-256 Checksums

Every production bundle includes verified SHA-256 cryptographic digests in `SHA256SUMS.txt`.
