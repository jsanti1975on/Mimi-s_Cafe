# 🧪 Forensic Startup Recovery (Jan 2026)

Dashboard upload server (port 8081) was running with no comment history.
Steps used to recover launch method:

1. Identified running Python process via `top`, `ps`, `lsof`
2. Found `server.py` bound to 0.0.0.0:8081 using `lsof -i :8081`
3. Confirmed it runs as root and has no systemd or crontab launcher
4. Located `start-dashboard.sh` in /opt/cyber-dash/scripts/
5. Startup handled via `nohup python3 scripts/server.py &`
6. Logs intended for `logs/dashboard.log`, but file redirect was misquoted

✔️ Now documented and confirmed for future use or reboot automation.

# Vulnerable by design 
