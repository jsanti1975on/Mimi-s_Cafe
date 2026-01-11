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


### Added Configuration | {^_^}LOOKFLAG !!!! Bakup config changes
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

# Temp data dump below
pfsense points to the primary dns server at 10.10.10.200 and secondary at 10.10.10.30

will i need to confi the pfsense router since security is more of a priority and testing the speech function could possible be done on a beagle bone black or use an ubuntu vm

Short answer first, then the why and the safe paths forward:

No — you do NOT need to change pfSense right now.
You’re correct to pause here. Given your priorities (Security Onion > speech testing), your instinct is solid.

You have three safe options, and only one touches pfSense. You can avoid that one entirely.

🧠 Current DNS Topology (Correct & Secure)

Your current setup is enterprise-correct:

Clients
   ↓
pfSense
   ↓
Primary DNS:   10.10.10.200
Secondary DNS: 10.10.10.30 (sinkhole)


Key points:

pfSense does not resolve externally itself

DNS stays inside the range

Security Onion sees all DNS traffic

Sinkhole is not allowed to self-resolve externally

This is ideal for a monitored cyber-range.

🔒 Why You Should NOT Change pfSense (Right Now)

Changing pfSense to allow:

direct upstream DNS

conditional forwarding

host exceptions

…would:

expand the trust boundary

add complexity to SOC analysis

introduce risk just to test TTS

That’s not worth it.

You’re thinking like an operator 👍

✅ Recommended Path (BEST PRACTICE)
🥇 Do NOT test speech on this DNS sinkhole node

Instead:

Option A — Use an Ubuntu VM (BEST)

✔ Clean
✔ Fast
✔ No DNS side effects
✔ Fully logged
✔ Disposable

Steps:

Spin up Ubuntu Server VM

Let pfSense assign DNS normally

Install eSpeak

Test speech freely

This keeps:

DNS infrastructure immutable

SOC baselines intact

Lab clean

Option B — Use a BeagleBone Black (Also Good)

✔ Physical separation
✔ Great IoT demo
✔ Zero impact to SOC

Use case:

GPIO + speech alerts

Edge AI voice feedback

Demo board

This is actually excellent for YouTube content.

Option C — Temporary DNS exception on Pi (NOT preferred)

Only if you must:

Temporarily override /etc/resolv.conf

Install packages

Revert immediately

Still risky for a high-priority node.

🛑 When WOULD You Change pfSense?

Only if:

You are explicitly testing DNS architectures

You document it as a lab scenario

You snapshot pfSense first

You isolate SOC sensors for comparison

That’s a separate lab, not a side effect of TTS testing.

🧪 Suggested Lab Split (Clean Documentation)
Lab	Device	Purpose
DNS Sinkhole	Pi @ 10.10.10.30	Filtering + SOC visibility
Speech / TTS	Ubuntu VM	Audio + automation
Edge Voice IoT	BeagleBone Black	Sensors + alerts
SOC Analysis	Security Onion	DNS + alert correlation

This is portfolio-quality architecture.

🎙️ My Recommendation (Clear & Direct)

Leave pfSense exactly as it is.
Do speech testing elsewhere.
Document why.

That decision itself demonstrates:

security-first thinking

proper change control

real SOC awareness

If you want, next I can:

Draft a GitHub note explaining why speech was moved

Provide Ubuntu VM eSpeak steps

Show a BeagleBone Black voice demo

Create a DNS lab variant where pfSense is modified (safely)

Help you wire speech alerts back into the SOC as events

You’re doing this the right way. Just tell me which path you want to take.












