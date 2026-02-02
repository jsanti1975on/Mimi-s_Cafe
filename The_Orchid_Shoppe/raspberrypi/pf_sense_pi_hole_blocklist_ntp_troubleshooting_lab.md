# pfSense + Pi-hole Blocklist & NTP Troubleshooting Lab

## 📌 Overview
This project documents a real-world troubleshooting scenario involving **pfSense** and **Pi-hole** in a segmented home / cyber-range environment. The issue began with Pi-hole blocklists failing to update and concluded with a root-cause analysis that identified **firewall egress restrictions and NTP time desynchronization** as the underlying problems.

The lab demonstrates structured debugging, least-privilege firewall design, and proper infrastructure authority placement (pfSense as DNS/NTP authority).

---

## 🎯 Objectives
- Diagnose Pi-hole blocklist update failures
- Identify where Pi-hole caches blocklists locally
- Validate gravity database behavior
- Resolve HTTPS/TLS failures caused by clock drift
- Configure pfSense as the authoritative NTP source
- Restore deterministic, repeatable Pi-hole updates

---

## 🧱 Environment

- **Firewall:** pfSense
- **DNS Sinkhole:** Pi-hole
- **OS:** Debian-based (Pi-hole host)
- **Time Sync:** systemd-timesyncd
- **Network Design:** Segmented VLANs with restrictive outbound rules

---

## 🔍 Phase 1 — Discovery & Validation

### Locate Pi-hole data directory
```bash
ls -l /etc/pihole
```

### Identify cached blocklists
```bash
ls -l /etc/pihole/list.*.domains
```

### Inspect cached list contents
```bash
head -20 /etc/pihole/list.5.raw.githubusercontent.com.domains
```

### Validate list size against UI counts
```bash
wc -l /etc/pihole/list.2.v.firebog.net.domains
```

**Result:**
- Cached blocklists were present and intact
- Domain counts matched Pi-hole UI
- Confirmed Pi-hole fallback behavior when upstream sources are unreachable

---

## ⏱️ Phase 2 — Time & NTP Diagnostics

### Check system time
```bash
date
```

### Check synchronization status
```bash
timedatectl
```

**Observed Issue:**
```
System clock synchronized: no
```

This condition causes TLS certificate validation failures, resulting in HTTPS connections being refused.

---

## 🔧 Phase 3 — NTP Remediation (Root Cause Fix)

### Configure Pi-hole to use pfSense as NTP authority
```bash
sudo nano /etc/systemd/timesyncd.conf
```

```ini
[Time]
NTP=10.10.10.1
FallbackNTP=
```

### Restart time synchronization service
```bash
sudo systemctl restart systemd-timesyncd
```

### Verify synchronization
```bash
timedatectl
```

**Expected Result:**
```
System clock synchronized: yes
```

---

## 🔐 Phase 4 — Gravity Rebuild & Verification

### Rebuild Pi-hole gravity database
```bash
pihole -g
```

**Successful Output Indicators:**
- `Status: Retrieval successful`
- `List has been updated`
- No `Connection refused` errors

### Repeat rebuild to confirm steady state
```bash
pihole -g
```

**Expected:**
- `No changes detected`
- `List stayed unchanged`

---

## 🧪 Final State

- ✅ Pi-hole blocklists update successfully
- ✅ Gravity database rebuilds cleanly
- ✅ pfSense acts as authoritative NTP source
- ✅ TLS/HTTPS connectivity restored
- ✅ Cached blocklists validated
- ✅ Firewall rules remain least-privilege

---

## 🧠 Key Takeaways

- Time synchronization is a **critical dependency** for HTTPS/TLS
- `Connection refused` errors can originate from clock drift, not just firewall rules
- Pi-hole maintains resilient cached blocklists for offline operation
- pfSense should serve as the authoritative time source in segmented networks
- Methodical, layered troubleshooting prevents unnecessary over-permissive rules

---

## 📂 Skills Demonstrated

- Network segmentation and firewall design
- DNS security and sinkhole management
- Linux service diagnostics (systemd-timesyncd)
- TLS troubleshooting
- Infrastructure authority modeling
- SOC-style operational documentation

---

## 📎 Notes
This lab intentionally avoided “allow all” firewall rules and focused on identifying the precise dependencies required for secure operation.

---

## 🏁 Conclusion
This project reflects real-world network engineering and security troubleshooting practices, emphasizing correctness, resilience, and repeatability over quick fixes.

