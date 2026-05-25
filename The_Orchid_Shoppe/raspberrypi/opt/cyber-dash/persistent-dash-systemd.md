# 🔁 Persistent Dashboard Deployment with systemd

## 📌 Overview

This phase of the cyber range project focused on converting the Cyber Dash web application into a persistent Linux service using `systemd`.

The objective was to ensure the dashboard:

* Starts automatically at boot
* Restarts after crashes
* Runs without an active terminal session
* Uses a dedicated Python virtual environment
* Maintains centralized logging

---

# 🧠 Environment Layout

## Application Directory

```bash
/home/dubz/opt/cyber-dash
```

## Python Virtual Environment

```bash
/home/dubz/opt/vSpring2026
```

---

# ⚠️ Initial Issue Encountered

The service initially failed to start with errors related to:

* incorrect `WorkingDirectory`
* invalid virtual environment paths
* outdated references to `/opt` instead of `~/opt`

Example failure:

```text
Changing to the requested working directory failed: No such file or directory
```

---

# 🔍 Root Cause

A distinction existed between:

```bash
/opt
```

and:

```bash
/home/dubz/opt
```

The application was hosted inside the user-space directory:

```bash
/home/dubz/opt
```

However, the original service configuration incorrectly referenced:

```bash
/opt/cyber-dash
```

This caused the service to fail during startup.

---

# ✅ Solution

## Startup Script

### `start-dash.sh`

```bash
#!/bin/bash

APP_DIR="/home/dubz/opt/cyber-dash"
VENV_DIR="/home/dubz/opt/vSpring2026"
LOG_FILE="$APP_DIR/server.log"

cd "$APP_DIR" || exit 1

source "$VENV_DIR/bin/activate"

exec python3 server.py >> "$LOG_FILE" 2>&1
```

---

# 🔐 Script Permissions

The startup script was made executable:

```bash
chmod +x ~/opt/cyber-dash/start-dash.sh
```

---

# ⚙️ systemd Service Configuration

## Service File

```ini
[Unit]
Description=Cyber Dash Upload Server
After=network.target

[Service]
Type=simple
User=dubz
WorkingDirectory=/home/dubz/opt/cyber-dash
ExecStart=/home/dubz/opt/cyber-dash/start-dash.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

---

# 🚀 Deployment Steps

## Reload systemd

```bash
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
```

---

## Enable Service at Boot

```bash
sudo systemctl enable cyber-dash
```

---

## Start Service

```bash
sudo systemctl start cyber-dash
```

---

# 🧪 Validation

## Check Service Status

```bash
systemctl status cyber-dash
```

Expected:

```text
Active: active (running)
```

---

## View Live Logs

```bash
journalctl -u cyber-dash -f
```

---

# 🌐 Functional Validation

After deployment:

* Dashboard remained accessible after reboot
* Upload endpoint remained active
* File uploads persisted correctly
* Python virtual environment activated successfully during startup

Example upload log:

```text
POST /upload HTTP/1.1 200
[+] Uploaded: program_2.png
```

---

# 🧠 Key Takeaways

* `systemd` is preferred over cron or manual startup scripts for persistent services
* Full absolute paths are critical in Linux service configurations
* User-space directories (`~/opt`) differ from system directories (`/opt`)
* Virtual environments can be integrated cleanly into persistent services
* `journalctl` provides centralized service logging and debugging

---

# 🛡️ Future Improvements

Planned enhancements:

* HTTPS support
* Authentication layer
* File hashing and upload auditing
* Dashboard upload panel integration
* SOC-style alert logging

---

# 📎 Portfolio Relevance

This deployment demonstrates:

* Linux service management
* Persistent application deployment
* Python virtual environment integration
* Troubleshooting of service startup failures
* Practical cyber range infrastructure administration
