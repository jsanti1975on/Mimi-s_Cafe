# Use directory to hold files
- Build notes
- Images
- AI conversations

## 01-11-2026 | Notes related to dns and rasp pi
# DNS Change Control — Secondary DNS / Sinkhole Node (redacted)

## Device Role
- **Hostname:** redacted
- **Role:** Secondary DNS Server + DNS Sinkhole
- **Priority:** HIGH (Infrastructure Control Plane)
- **Range Impact:** Affects all dependent VLANs and SOC tooling (e.g., Security Onion)

---

## Problem Statement
The DNS sinkhole node was unable to resolve external domains required for:
- OS updates (`apt update`)
- Package installation (e.g., `espeak`, `alsa-utils`)
- Time sync, TLS validation, and threat feed retrieval

**Observed Error:**
- Could not resolve **deb.debian.org**

Root cause:  
The node was configured to resolve DNS queries **against itself only**, causing its own outbound DNS requests to be blocked by sinkhole policies.

---

## Design Constraint
This node must:
- Continue filtering DNS for downstream clients
- Retain sinkhole protections
- Avoid bypassing pfSense / SOC visibility
- NOT break Security Onion DNS telemetry

---

## Approved Solution (Split DNS Resolution)

The DNS sinkhole forwards **its own queries** to a trusted upstream resolver while continuing to filter client traffic.

### Configuration Change
File modified:
```bash
/etc/dhcpcd.conf
```


### Added Configuration
```ini
# Allow sinkhole host to resolve external domains
# while continuing to filter downstream clients
static domain_name_servers=127.0.0.1 1.1.1.1
```

Behavior After Change

Clients → DNS sinkhole → filtered

DNS sinkhole → upstream resolver → allowed

SOC tools retain full visibility

No direct DNS bypass introduced


Note: do a sudo systemctl daemon reload
or just sudo service dhcpcd restart
sudo reboot














