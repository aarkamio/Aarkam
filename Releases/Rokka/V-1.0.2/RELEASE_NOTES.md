# Rokka Sovereign Storage Engine & Distributed Fabric
# Official Production Release Notes (Version 1.0.2-GA)

| Release Metadata | Specification |
| :--- | :--- |
| **Product** | Rokka Sovereign Storage Engine & Distributed Control Plane |
| **Release Version** | `v1.0.2-GA (General Availability)` |
| **Release Date** | November 2026 |
| **Architectural Role** | Autonomous Sovereign Storage Data Plane & Control Plane |
| **Dependency Scope** | Core Substrate for **Aarkam - SAT (Standalone Tier)** & **Aarkam - SCT (Storage Centers Tier)** |
| **Compliance Level** | Saudi NCA ECC-2:2024, NCA CSCC-1:2023, FIPS 140-3 Zero-Trust Architecture |
| **Target Distribution** | Zero-Egress Air-Gapped Datacenters (Linux x64, Windows Server x64, OCI Container) |

---

## 1. Executive Summary

**Rokka v1.0.2-GA** is a critical security, networking, and platform hardening release establishing end-to-end sovereign endpoint normalization (`*.aarkam`), complete decoupling of daemon configurations, strict zero-trust environment variable key management, and ecosystem-wide package modernization on **.NET 10**.

Together with **Abodi v1.0.2** and **AM CLI v1.0.2**, this release completes seamless integration across the entire sovereign storage fabric.

---

## 2. What's New in Version 1.0.2-GA

### 2.1 Sovereign Endpoint Normalization (`*.aarkam`)
- **Default Sovereign Cluster FQDN**: Standardized all internal cluster endpoints to sovereign enterprise domains:
  - Coordinator Control Plane: `https://rokka-coordinator.aarkam:57774`
  - Coordinator gRPC: `http://rokka-coordinator.aarkam:7774`
  - S3 Data Gateway (HTTPS): `https://rokka-gateway.aarkam:57772`
  - S3 Data Gateway (HTTP): `http://rokka-gateway.aarkam:7772`
- **Flexible On-Premises & Standard Port 443 Support**:
  - The URL normalizer accepts raw hostnames, IPv4/IPv6 addresses, custom paths, and optional ports.
  - Automatically handles standard HTTPS port `443` without appending extraneous port numbers (e.g. `https://rokka-coordinator.aarkam`).
  - Auto-prefixes `https://` if protocol scheme is omitted by the operator.
- **Cross-Component Trust Validation**:
  - Abodi token validator updated to accept `https://rokka-coordinator.aarkam`, `https://rokka-gateway.aarkam`, `https://abodi.aarkam`, `urn:rokka:gateway`, and `urn:rokka:abodi`.
  - AM CLI updated to automatically normalize all target coordinator addresses.

### 2.2 Daemon Port Separation & Packaging Cleanup
- **Port Matrix Conflict Resolution**: Fixed configuration inheritance where `rokka-gateway` was binding to Coordinator's HTTPS port `57774`. Gateway and Coordinator settings are now completely decoupled into `gateway.settings.json` and `coordinator.settings.json`.
- **Eliminated Duplicate Executables**: Removed redundant PascalCase binaries (`Rokka.Coordinator.exe`, `Rokka.Gateway.exe`) in favor of canonical lowercase executables (`rokka-coordinator.exe`, `rokka-gateway.exe`).
- **Removed Conflicting `appsettings.json`**: Stopped creating generic `appsettings.json` in release staging to prevent port cross-contamination.

### 2.3 Zero-Trust Secret Key Management (CWE-312)
- **Eliminated Plaintext Secrets from JSON**: Cryptographic keys (`ROKKA_MASTER_KEY`, `ROKKA_WAL_ENCRYPTION_KEY`, `ROKKA_SECRET_ACCESS_KEY`) are no longer written into `gateway.settings.json` or `coordinator.settings.json`.
- **Environment-First Resolution**: Daemons prioritize machine/system environment variables:
  - `ROKKA_MASTER_KEY` (AES-256 sovereign cluster master key)
  - `ROKKA_WAL_ENCRYPTION_KEY` (Kdouja LSM WAL metadata encryption)
  - `ROKKA_ACCESS_KEY_ID` & `ROKKA_SECRET_ACCESS_KEY` (S3 SigV4 API credentials)
  - `ROKKA_CLUSTER_CA_PASSWORD` (Internal cluster mTLS root CA passphrase)
- **Installer Clarity**: Windows and Linux installation banners explicitly distinguish between local service environment injection and enterprise vault backup requirements for disaster recovery.

### 2.4 Ecosystem-Wide Package & Security Modernization
- **Runtime Standard**: Strictly maintained on the latest **.NET 10** (`net10.0`).
- **API Gateway**: Updated Ocelot to `25.0.2` and `Ocelot.QualityOfService.Polly` to `25.0.2`.
- **Core Networking & Protobuf**: Synchronized `Grpc.AspNetCore` and `Grpc.Net.Client` to `2.84.0`, and `Google.Protobuf` to `3.36.2`.
- **Platform Libraries**: Modernized `Microsoft.Extensions.*` packages to `10.0.11` / `10.0.0`, `Microsoft.AspNetCore.Authentication.JwtBearer` to `10.0.11`, and `System.Security.Cryptography.ProtectedData` to `10.0.0`.
- **PowerShell Installer Hardening**: Replaced fragile `sc.exe create` with native PowerShell `New-Service` and defensive status checking.

---

## 3. Package & Distribution Matrix

| Artifact Name | Target Architecture | Contents | Distribution Channel |
| :--- | :--- | :--- | :--- |
| **`rokka-v1.0.2-linux-x64.zip`** | Linux x64 (glibc 2.31+) | Single-file `rokka-coordinator`, `rokka-gateway`, `install-rokka.sh`, settings | [GitHub Releases](https://github.com/Aarkam-IO/Aarkam.Rokka/releases) |
| **`rokka-v1.0.2-win-x64.zip`** | Windows Server x64 (2022/2025) | Single-file `rokka-coordinator.exe`, `rokka-gateway.exe`, `install-rokka.ps1` | [GitHub Releases](https://github.com/Aarkam-IO/Aarkam.Rokka/releases) |
| **`aarkam/aarkam.rokka:v1.0.2`** | OCI Container (Linux x64) | Production-hardened container image with embedded daemons and entrypoint | [Docker Hub Repository](https://hub.docker.com/r/aarkam/aarkam.rokka) |
