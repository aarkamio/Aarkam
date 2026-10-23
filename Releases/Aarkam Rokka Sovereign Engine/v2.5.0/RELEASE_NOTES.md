# Aarkam Sovereign Cloud & Tier 1 Storage Substrate
# Production Release Notes (Version 2.5.0-GA)

| Release Metadata | Specification |
| :--- | :--- |
| **Release Version** | `v2.5.0-GA (General Availability)` |
| **Release Date** | October 2026 |
| **Product Line** | Aarkam Sovereign Enterprise Cloud & Storage Fabric |
| **Classification** | Official Engineering GA Release Notes |
| **Compliance Level** | Saudi NCA ECC-2:2024, NCA CSCC-1:2023, FIPS 140-3 Zero-Trust Architecture |
| **Target Distribution** | Zero-Egress Air-Gapped Datacenters (Linux x64, Windows Server x64) |

---

## 1. Executive Summary

The **Aarkam Tier 1 Sovereign Storage Substrate v2.5.0** marks the official General Availability (GA) production milestone of Aarkam's zero-trust, air-gapped sovereign storage platform.

Prior versions required external database engines and relied on cloud coordination services. Version 2.5.0 achieves complete autonomous sovereignty:
- **Zero Cloud Dependence**: Operates in 100% disconnected, zero-egress environments with zero outbound DNS, telemetry, or licensing pings.
- **Zero External Database**: Eliminates PostgreSQL / SQL Server dependencies. All cluster catalogs, node registries, and identity stores are powered directly by the embedded **Kdouja LSM-Tree Engine**.
- **Cryptographic Genesis Ceremony**: Permanently eradicates hardcoded administrative credentials. Administrative operators are provisioned via mathematically sealed, RSA-4096-PSS signed `.arkbundle` envelopes bound to deterministic physical hardware fingerprints (`ARK-FP-...`).
- **Complete Substrate Integration**: Unifies **Rokka** (Consensus & S3 Gateway), **Abodi** (Direct I/O Chunk Storage), **Ahmodi** (AVX SIMD Cauchy Reed-Solomon Erasure Coding), and **AM CLI** (Zero-Trust Operator Management) into standalone, single-file native binaries.

---

## 2. Major Highlights & New Capabilities

### 2.1 Sovereign Cluster Genesis Ceremony (One-Time Activation)
- **Elimination of Default Passwords**: Adheres to Saudi NCA ECC-2:2024 Control §2-1-3. No pre-seeded database accounts or default passwords exist in code.
- **Hardware Profile Binding**: Deterministically extracts machine GUIDs, CPU topology, and network MAC addresses to generate a unique cluster fingerprint (`ARK-FP-XXXXXXXX-XXXXXXXX-XXXXXXXX`).
- **Cryptographic Activation Bundle (`.arkbundle`)**: Licenses and initial sovereign operator credentials are sealed in an encrypted, RSA-4096-PSS signed envelope. Operator passwords are cryptographically hashed using **PBKDF2-HMAC-SHA512** with 600,000 iterations and 256-bit unique salts.
- **Immutable State Sealing**: Once applied via `am license apply`, the cluster transitions irreversibly to `IsBootstrapped = true`, permanently disabling bootstrap endpoints.

### 2.2 Sub-Microsecond Zero-Trust Authentication & RBAC
- **Cluster-Authoritative Interceptor**: Server-side gRPC interceptors inside `Rokka.Coordinator` cryptographically validate JWT session tokens against in-memory cluster public keys in under **800 nanoseconds**.
- **Epoch-Monotonic Instant Revocation**: Operator password rotations or role modifications automatically increment the operator's `SecurityEpoch`. Outdated sessions are instantly rejected across the cluster without database queries.
- **Secure Local Credential Persistence**:
  - **Windows**: Protected using DPAPI (Data Protection API) via `ProtectedData.Protect` with CurrentUser scope (`%LOCALAPPDATA%\Aarkam\am_auth.dat`).
  - **Linux**: Protected using POSIX file permissions (`0600`) restricted strictly to the executing user (`~/.aarkam/am_auth.dat`).
- **Granular RBAC Enforced Across 28 CLI Domains**: Preflight and server-side authorization guards validate operator roles (`ClusterAdmin`, `StorageOperator`, `SecurityOfficer`, `Auditor`) prior to executing cluster mutations.

### 2.3 Direct I/O Kdouja PageStore & 66,048-Byte Sector Alignment
- **Kdouja LSM Storage Engine**: High-throughput Log-Structured Merge Tree engine provides lock-free, O(log N) key-value access with persistent write-ahead logs (WAL).
- **Physical Sector Invariant**: Enforces exact 66,048-byte physical page sector geometry (`PhysicalPageSizeBytes` = 512-byte header + 64KB payload).
- **Zero Kernel Buffer Double-Caching**: Chunks written by Abodi bypass the OS page cache via `FILE_FLAG_NO_BUFFERING` (`O_DIRECT` on Linux), achieving predictable, microsecond NVMe write latencies.

### 2.4 Ahmodi Cauchy Reed-Solomon SIMD Erasure Coding
- **Galois Field SIMD Optimization**: Employs Cauchy-Vandermonde matrices over $\text{GF}(2^8)$ optimized with AVX2 and AVX-512 SIMD vector instructions.
- **Flexible Stripe Configurations**: Native support for **4+2**, **8+4**, and **16+4** data/parity layouts.
- **Transparent Authenticated Encryption**: Chunks are transparently encrypted and authenticated inline using **AES-256-GCM** with authenticated 128-bit integrity tags.
- **Single-Node & Edge Dynamic Cycling**: If the cluster has fewer physical nodes than total stripe chunks ($N < K+M$), the placement and download engines automatically cycle stripe chunks across online nodes without throwing `ArgumentOutOfRangeException`.

### 2.5 AWS SigV4 Sovereign S3 Gateway
- **Unified S3 Endpoint**: S3 traffic is unified on port **7772** (with legacy fallback on 57772) with strict AWS Signature Version 4 (SigV4) authentication.
- **Full S3 API Coverage**:
  - `CreateBucket` / `DeleteBucket` / `ListBuckets`
  - `PutObject` / `GetObject` / `DeleteObject` / `HeadObject`
  - `ListObjectsV2` XML catalog responses
- **Streaming Hedged Download Pipeline**: Reads data chunks concurrently with adaptive speculative execution and on-the-fly Cauchy reconstruction for resilient sub-millisecond retrieval.

---

## 3. The 12 Architectural Gap Remediations (GAP-01 to GAP-12)

The 12 architectural, security, and performance gaps identified in earlier iterations have been remediated and certified:

| Gap ID | Subsystem | Severity | Description & Root Cause | Technical Remediation | Validation Status |
| :---: | :--- | :---: | :--- | :--- | :---: |
| **GAP-01** | `Rokka.Gateway` | **Critical (P0)** | **Physical Chunk Leakage on S3 Delete**: `app.MapDelete` removed catalog entries without deallocating physical blocks on Abodi storage nodes. | Implemented end-to-end `ReleasePageAsync` propagation down to Abodi's `PageStore`, reclaiming disk space immediately. | **CLOSED & VERIFIED** |
| **GAP-02** | `Rokka.Gateway` | **Critical (P0)** | **Monolithic JSON Catalog Serialization**: Global section lock rewrote monolithic `.json` file on every PUT/DELETE, causing lock contention at scale. | Replaced with decoupled Kdouja LSM-Tree catalog store with prefix `0x20`, achieving lock-free O(log N) catalog operations. | **CLOSED & VERIFIED** |
| **GAP-03** | `Rokka.Gateway` | **Critical (P0)** | **Dual-Port Split & Missing AWS SigV4**: Port 7771 allowed unauthenticated REST bypass, while Port 7772 lacked AWS SigV4 validation. | Unified S3 ingress on Port 7772 with strict SigV4 authorization pipeline; eliminated unprotected Port 7771. | **CLOSED & VERIFIED** |
| **GAP-04** | `Rokka.Common` | **High (P1)** | **GrpcChannelHelper Air-Gap Hangs**: Missing `CustomTrustStore` and online CRL checks caused 30-second connection timeouts in offline environments. | Configured `SocketsHttpHandler` with `X509RevocationMode.NoCheck` and custom CA trust store for instant air-gapped handshake. | **CLOSED & VERIFIED** |
| **GAP-05** | `AM.CLI` | **Critical (P0)** | **Hardcoded Coupling to Aarkam.IO**: CLI commands relied on `AARKAM_URL` (Port 57771), breaking execution in air-gapped environments. | Refactored AM CLI to target Sovereign `Rokka.Coordinator` directly (Port 7774/57774) with zero cloud dependencies. | **CLOSED & VERIFIED** |
| **GAP-06** | `AM.CLI` | **Medium (P2)** | **Legacy Non-Standard S3 URL Prefix**: CLI injected `/api/v1/GW/S3` into requests, breaking interoperability with AWS CLI and standard S3 clients. | Normalized Gateway routes to standard S3 REST endpoints (`/{bucket}/{object}`) with path-style and virtual-host addressing. | **CLOSED & VERIFIED** |
| **GAP-07** | `Rokka.Contracts` | **Critical (P0)** | **Absence of Generic Key-Value APIs**: Kdouja was encapsulated as a private store with no generic distributed KV interface. | Exposed generic `Get`, `Put`, `Delete`, `Scan`, and `Compact` gRPC and REST APIs for direct low-latency metadata access. | **CLOSED & VERIFIED** |
| **GAP-08** | `Rokka.Contracts` | **High (P1)** | **Missing Block Deallocation in Proto**: `kdouja.proto` lacked a deallocation RPC, making remote chunk reclamation impossible. | Defined and implemented `ReleasePageAsync` RPC in `kdouja.proto`, `Abodi`, and `RokkaClient`. | **CLOSED & VERIFIED** |
| **GAP-09** | `Coordinator` | **High (P1)** | **Insecure Static API Keys**: Node-to-Coordinator channels used static header keys (`x-aarkam-node-key`) instead of zero-trust mutual TLS. | Migrated to mTLS mesh with dynamic X.509 certificates and SPIFFE SAN identity verification (`spiffe://aarkam.cluster/node/*`). | **CLOSED & VERIFIED** |
| **GAP-10** | `Coordinator` | **High (P1)** | **Reactive Hardware Failure Recovery**: Rebuilds only triggered *after* a drive failed, risking data loss during degraded states. | Integrated SMART drive telemetry from Abodi into Coordinator to trigger proactive Cauchy reconstruction before failure. | **CLOSED & VERIFIED** |
| **GAP-11** | `Rokka.Gateway` | **Medium (P2)** | **Incomplete S3 Bucket & Listing Semantics**: Missing standard XML `ListObjectsV2`, HEAD bucket/object metadata, and bucket CRUD. | Implemented full S3 XML serialization for `ListBucketResult` and compliant HTTP response headers (`ETag`, `Content-Length`). | **CLOSED & VERIFIED** |
| **GAP-12** | `Aarkam.IO` | **Medium (P2)** | **Monolithic Platform Inversion**: CLI could not be embedded or driven through browser-based terminals in edge deployments. | Added WebSocket terminal bridge (`/ws/terminal`) enabling zero-install interactive CLI sessions via web browser. | **CLOSED & VERIFIED** |

---

## 4. Verification Evidence & Quality Assurance

### 4.1 Automated Test Execution Suite
All 482 unit and integration tests across the substrate repositories are passing:

| Subsystem / Repository | Passing Tests | Pass Rate | Test Focus Areas |
| :--- | :---: | :---: | :--- |
| **`Aarkam.AM`** | **174 / 174** | **100%** | Hardware profiling, DPAPI store, RBAC preflight, SigV4 client, license verification |
| **`Aarkam.Rokka`** | **224 / 224** | **100%** | Raft consensus, S3 Gateway, Hedged reads, Kdouja LSM catalog, JWT interceptor |
| **`Aarkam.Abodi`** | **48 / 48** | **100%** | Direct I/O 66,048B alignment, PageStore, SMART telemetry, page release |
| **`Aarkam.Ahmodi`** | **36 / 36** | **100%** | Cauchy GF(2^8) SIMD matrix math, AES-256-GCM chunk cipher, SIMD error correction |
| **Total Test Suite** | **482 / 482** | **100%** | **Full substrate certified ready for production deployment** |

### 4.2 End-to-End Air-Gapped Verification Scenario
An exhaustive end-to-end air-gapped test was executed on physical hardware:
1. **Cluster Hardware Profiling**: `am cluster fingerprint` generated deterministic hardware identity (`ARK-FP-AD8FF9EE-77AEB122-F222165B`).
2. **Genesis Ceremony**: Portal generated an encrypted `.arkbundle` containing sovereign operators (`secadmin`, `storageop`, `auditor`).
3. **Cluster Activation**: `am license apply --bundle genesis.arkbundle` verified the RSA-4096-PSS signature, matched the hardware lock, and ingested operators into Kdouja.
4. **Zero-Trust Login**: `am auth login -u secadmin` authenticated via PBKDF2-HMAC-SHA512 and cached the token in DPAPI.
5. **S3 Bucket Creation**: `am s3 mb s3://sovereign-vault` created the bucket catalog record in Kdouja.
6. **Cauchy 4+2 EC Streaming Upload**: `am s3 cp test_payload.txt s3://sovereign-vault/test_payload.txt` encoded chunks via Ahmodi AVX2 SIMD, encrypted chunks via AES-256-GCM, and wrote 66,048-byte aligned pages via Abodi Direct I/O (ETag: `"68d23eff1a3a4cfc806f8ff941d10504"`).
7. **S3 Metadata Inspection**: `am s3 stat s3://sovereign-vault/test_payload.txt` returned verified size and ETag.
8. **Streaming Download & SIMD Reconstruction**: `am s3 cp s3://sovereign-vault/test_payload.txt downloaded_payload.txt` reconstructed original payload on the fly.
9. **Bit-for-Bit SHA-256 Verification**:
   - `Source SHA256`: `210186B908EFC48F6B7C00D027C705FCCF614C5BE968DFC1164FE4ADADC70256`
   - `Dest SHA256`:   `210186B908EFC48F6B7C00D027C705FCCF614C5BE968DFC1164FE4ADADC70256`
   - **Result**: **100% bit-for-bit identity match across the storage substrate.**

---

## 5. Performance Benchmarks

Measured on dual-socket AMD EPYC 9654 (192 Cores) with Micron 9400 NVMe SSDs over 100GbE RoCEv2:

| Metric | Measured Value | Standard Target | Performance Headroom |
| :--- | :---: | :---: | :---: |
| **Cauchy Erasure Coding (AVX-512)** | **3,420 MB/s** | > 1,500 MB/s | **+128%** |
| **Cauchy Erasure Coding (AVX2)** | **1,890 MB/s** | > 1,000 MB/s | **+89%** |
| **Direct I/O 64KB Page Write Latency** | **184 μs** | < 500 μs | **+171%** |
| **Kdouja LSM Point Lookup Latency** | **3.8 μs** | < 10 μs | **+163%** |
| **Asymmetric JWT Verification Latency** | **780 ns** | < 5 μs | **+541%** |
| **S3 GET Hedged Read p99 Latency** | **1.2 ms** | < 5.0 ms | **+316%** |

---

## 6. Distribution Packages & Deployment Artifacts

The compiled standalone release bundles are packaged in `dist/bundles/`:

| Artifact Filename | Platform | Contents | Size |
| :--- | :--- | :--- | :---: |
| **`rokka-substrate-v2.5.0-linux-x64.zip`** | Linux x64 | `rokka-coordinator`, `rokka-gateway`, `abodi`, `am`, configurations, documentation | **~130 MB** |
| **`rokka-substrate-v2.5.0-win-x64.zip`** | Windows x64 | `rokka-coordinator.exe`, `rokka-gateway.exe`, `abodi.exe`, `am.exe`, configurations, documentation | **~174 MB** |
| **`am-cli-v2.5.0-linux-x64.zip`** | Linux x64 | Standalone `am` CLI executable + `appsettings.json` + documentation | **~35 MB** |
| **`am-cli-v2.5.0-win-x64.zip`** | Windows x64 | Standalone `am.exe` CLI executable + `appsettings.json` + documentation | **~32 MB** |

---

## 7. Migration & Upgrade Instructions

### Upgrading from v2.4.x Preview:
1. **Backup Metadata**: Create a snapshot of the Kdouja metadata directory (`/var/lib/aarkam/coordinator` or `C:\Aarkam\data\coordinator`).
2. **Stop Running Services**:
   ```bash
   sudo systemctl stop rokka-gateway abodi-node rokka-coordinator
   ```
3. **Replace Binaries**: Unpack the v2.5.0 distribution bundle into `/opt/aarkam` (or `C:\Aarkam`).
4. **Ingest Genesis Bundle**: If migrating from an unauthenticated preview, perform the Genesis Ceremony using `am cluster fingerprint` and `am license apply --bundle genesis.arkbundle`.
5. **Restart Services**:
   ```bash
   sudo systemctl start rokka-coordinator abodi-node rokka-gateway
   ```
6. **Verify Upgrade**: Execute `am doctor` and `am auth login` to verify the upgrade.

---
**Aarkam Sovereign Systems Engineering Group**  
*Certified Production Release — October 2026*
