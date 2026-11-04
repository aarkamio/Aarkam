# Rokka Sovereign Storage Engine — Standalone Installation Guide

| Specification | Standard |
| :--- | :--- |
| **Document Identifier** | `ARK-ROKKA-INSTALL-V1.0.0` |
| **Product** | Rokka Sovereign Storage Engine (`Rokka.Coordinator` & `Rokka.Gateway`) |
| **Release Version** | `V-1.0.0-GA (Production)` |
| **Classification** | Enterprise Operations Standard |
| **Target Distribution** | Linux x64 & Windows Server x64 (Air-Gapped / Zero-Egress) |

---

## 1. Quick Start

### Windows Server (x64)
1. Download or unpack `rokka-v1.0.0-win-x64.zip`.
2. Open PowerShell as Administrator.
3. Run the installer:
   ```powershell
   .\install-rokka.ps1 -StartServices
   ```
4. Verify daemon health:
   ```powershell
   rokka-coordinator --version
   rokka-gateway --version
   ```

### Linux (x86_64)
1. Download or unpack `rokka-v1.0.0-linux-x64.zip`.
2. Run the installer as root:
   ```bash
   sudo ./install-rokka.sh --start-services
   ```
3. Verify systemd status:
   ```bash
   sudo systemctl status rokka-coordinator
   sudo systemctl status rokka-gateway
   ```

---

## 2. Directory Layout

### Windows Server
- Binary installation directory: `C:\Program Files\Aarkam\Rokka`
  - `rokka-coordinator.exe`
  - `rokka-gateway.exe`
  - `coordinator.settings.json`
  - `gateway.settings.json`
- Data & Metadata directory: `C:\ProgramData\Rokka`
  - `Coordinator\metadata\` (LSM KeyValueEngine)
  - `Logs\`

### Linux
- Binary installation directory: `/opt/aarkam/rokka`
  - `rokka-coordinator`
  - `rokka-gateway`
  - `coordinator.settings.json`
  - `gateway.settings.json`
- Data & Metadata directory: `/var/lib/rokka`
  - `metadata/`
  - `logs/`

---

## 3. Firewall Configuration

| Port | Service | Protocol |
| :--- | :--- | :--- |
| `7774` | `rokka-coordinator` | TCP (HTTP/2 gRPC) |
| `57774` | `rokka-coordinator` | TCP (HTTPS/mTLS) |
| `7772` | `rokka-gateway` | TCP (HTTP S3 REST) |
| `57772` | `rokka-gateway` | TCP (HTTPS S3 REST) |
