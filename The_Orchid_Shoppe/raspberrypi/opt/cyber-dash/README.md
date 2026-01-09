# Cyber-Dash Ecosystem  
**Portfolio Project | Cyber Range | Kiosk-Based Learning Environment**

This repository documents the design, implementation, and roadmap of a **Windows-based kiosk launcher and multi-dashboard cyber range**, built for cybersecurity education, ethical hacking assessments, and portfolio presentation.

The project intentionally blends **modern security tooling** with **legacy Windows domain environments** to simulate real-world enterprise and government infrastructures commonly encountered during penetration tests and final exam assessments.

---

## 🚀 Project Overview

A **Windows workstation** launches a hardened `.exe` kiosk application that opens a **central HTTP dashboard**.  
From this dashboard, users can navigate to a controlled cyber range containing:

- Vulnerable legacy systems
- Modern servers and dashboards
- Offensive and defensive tooling
- IoT and monitoring environments
- Certificate-based trust boundaries

This environment is explicitly designed to resemble **ethical hacking final exam assessments**, where legacy systems coexist with newer infrastructure and misconfigurations must be identified, exploited, and documented.

---

## 🖥️ Windows POS → Cyber-Dash Launcher

### Features
- Kiosk-style `.exe` launcher
- Opens the primary HTTP dashboard
- No PowerShell or batch scripts required
- Controlled via `.env` configuration file
- Fullscreen / restricted user experience

### Dashboard Capabilities
- Upload files:
  - Jumpbox payloads
  - Sinkhole samples
  - Vulnerable web app files
- Browse uploaded files
- **Tux Talks**
  - Links to:
    - vSphere Host
    - DVWA
    - IoT Dashboard
- **Cheats Dashboard**
  - Web UI
  - Common ethical hacking tools
  - Base64 challenge (intro CTF mechanic)

---

## 🌐 Primary HTTP Dashboard (Core Hub)

Acts as the **central navigation point** for the cyber range.

### Linked Services
- East Side Server (IoT Subnet Dashboard)
- OWASP DVWA
- Pi-hole Dashboard
  - Logs
  - Charts
  - Settings
- vSphere Host
- Coming Soon:
  - Attacker VM (browser-accessible)
  - Headless RHEL10 console via HTTP

### Security Model
- Read-only access from POS subnet
- Admin dashboards restricted via VLAN + certificates
- Designed to demonstrate **defense-in-depth**

---

## 🏢 Legacy Windows Domain Environment (Planned)

To accurately reflect **real-world ethical hacking assessments**, this cyber range includes a **mixed-generation Windows domain**.

### Planned Domain Systems
- **Windows Small Business Server 2008**
  - Legacy Domain Controller
  - Outdated authentication mechanisms
  - Common misconfigurations used in exams
- **Windows Server 2019**
  - Configured as a **Read-Only Domain Controller (RODC)**
  - Used to demonstrate:
    - Credential caching risks
    - Physical site compromise scenarios
- **Windows 8**
  - Legacy domain-joined workstation
  - Weak endpoint protections
- **Windows 10**
  - Mixed hardening levels
  - Used for comparison against legacy hosts

### Purpose
This environment mirrors **Ethical Hacking Final Exam assessments**, where candidates must:
- Enumerate legacy Active Directory environments
- Identify outdated protocols and services
- Exploit weak authentication and trust relationships
- Pivot between legacy and modern systems
- Demonstrate post-exploitation awareness

---

## 🧠 East Side Server (IoT Subnet)

### Directory Structure

```bash
/opt/cyber-dash
├── Rag_Text/                 # Start with .txt files only (RAG-safe)
├── cheats/
│   ├── css/
│   ├── data/
│   │   └── tools.json
│   ├── js/
│   ├── scripts/
│   │   └── server.py
│   ├── tools/
│   ├── txt/
│   └── uploads/
├── files/
├── index.html
├── LOG_FILE
├── scripts/
│   ├── server.py
│   └── start-dashboard.sh
├── style.css
├── tux-talks.html
└── uploads/
