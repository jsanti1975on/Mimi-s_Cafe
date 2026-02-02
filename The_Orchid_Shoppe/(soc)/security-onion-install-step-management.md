# Security Onion 2.4 – Management Network Configuration (Redacted)
<img width="1934" height="1094" alt="sec-onion-2026 - Copy" src="https://github.com/user-attachments/assets/d17a91ed-e140-475a-8c94-54fa05f02fc3" />

## Overview
This document captures the **validated management-network configuration** used during the installation of **Security Onion 2.4 (EVAL mode)** in a segmented home cyber-range environment.

All sensitive identifiers (IP addresses, gateways, DNS servers, and FQDNs) have been **intentionally redacted** to allow safe sharing and reuse as a template.

---

## Platform Details

- **Security Onion Version:** 2.4.x  
- **Base OS:** Oracle Linux 9  
- **Deployment Type:** Standalone (EVAL)  
- **Node Role:** Manager + Sensor  
- **Hypervisor:** vSphere / ESXi  
- **Install Method:** ISO-based installation  

---

## Host Identity

| Setting        | Value (Redacted) |
|----------------|------------------|
| Hostname       | `so-eval` |
| DNS Domain     | `example-lab.local` |

---

## Management Network Configuration

> This interface is used **only** for administration, SOC UI access, updates, and internal name resolution.

| Setting              | Value (Redacted) |
|----------------------|------------------|
| Network Mode         | Static |
| Management Interface | `ensXX` |
| Management IP        | `MGMT_IP_ADDRESS` |
| Gateway              | `MGMT_GATEWAY` |
| DNS Server (Primary) | `DNS_PRIMARY` |
| DNS Server (Secondary) | `DNS_SECONDARY` |

### Notes
- The management IP is **outside the DHCP scope** or statically reserved.
- The management network is a **trusted administrative zone**.
- No monitored or hostile traffic traverses this interface.

---

## SOC Access Control

| Setting | Value |
|-------|-------|
| Allowed Subnet | `MGMT_SUBNET` |
| Web User | `analyst@example-lab.local` |
| SOC Telemetry | Disabled |

### Rationale
- SOC UI access is limited to the management subnet only.
- Telemetry is disabled for lab privacy and offline operation.

---

## Monitor Interface (Not Shown on Summary Screen)

> The monitor interface is selected **after** this confirmation screen.

- Connected to: **Screened / OPT1 subnet**
- IP Address: **None**
- Gateway: **None**
- DNS: **None**
- Mode: **Passive / Sniff-only**

### vSphere Port Group Requirements
The port group connected to the monitor interface must allow:
- Promiscuous Mode: **Accept**
- MAC Address Changes: **Accept**
- Forged Transmits: **Accept**

---

## Validation Checklist

- [x] Management interface reachable from admin workstation  
- [x] DNS resolution working on management network  
- [x] SOC UI accessible via HTTPS  
- [x] Monitor interface configured with no IP  
- [x] No routing between management and monitored networks  

---

## Snapshot Recommendation

After successful deployment and first login:


This snapshot provides a stable rollback point prior to enabling traffic mirroring or lab activity.

---

## Usage Notes

This document is intended for:
- Cyber-range documentation
- Academic coursework submissions
- Repeatable lab builds
- GitHub portfolio artifacts

Sensitive values should be replaced with environment-specific parameters during reuse.

---
