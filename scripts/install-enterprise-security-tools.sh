#!/usr/bin/env bash
# ubuntu-ops enterprise security toolkit installer
# Target: Ubuntu Server/Desktop 22.04, 24.04, or newer
# Usage:
#   sudo bash install-enterprise-security-tools.sh
#   sudo bash install-enterprise-security-tools.sh --profile full --analyst USER
#
# This script intentionally does not install exploit frameworks, password-
# cracking suites, DVWA, or Juice Shop. Keep vulnerable targets isolated.

set -Eeuo pipefail
IFS=$'\n\t'

PROFILE="core"
ANALYST_USER="${SUDO_USER:-}"
INSTALL_ZAP=false
ENABLE_UFW=false
LOG_FILE="/var/log/ubuntu-ops-security-tools-install.log"

usage() {
  cat <<'EOF'
Usage: sudo bash install-enterprise-security-tools.sh [options]

Options:
  --profile core|full   core = daily operations; full = adds IDS/IR tooling
  --analyst USER        user granted non-root Wireshark capture access
  --with-zap            install OWASP ZAP from Snap when Snap is available
  --enable-ufw          enable UFW after adding an OpenSSH allow rule
  -h, --help            display this help
EOF
}

while (($#)); do
  case "$1" in
    --profile)
      [[ $# -ge 2 ]] || { echo "Missing value for --profile" >&2; exit 2; }
      PROFILE="$2"; shift 2 ;;
    --analyst)
      [[ $# -ge 2 ]] || { echo "Missing value for --analyst" >&2; exit 2; }
      ANALYST_USER="$2"; shift 2 ;;
    --with-zap) INSTALL_ZAP=true; shift ;;
    --enable-ufw) ENABLE_UFW=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

[[ "$PROFILE" == "core" || "$PROFILE" == "full" ]] || {
  echo "--profile must be core or full" >&2
  exit 2
}

[[ $EUID -eq 0 ]] || { echo "Run this script with sudo." >&2; exit 1; }
[[ -r /etc/os-release ]] || { echo "Cannot identify this Linux distribution." >&2; exit 1; }

# shellcheck disable=SC1091
source /etc/os-release
[[ "${ID:-}" == "ubuntu" ]] || {
  echo "This installer supports Ubuntu. Detected: ${PRETTY_NAME:-unknown}" >&2
  exit 1
}

if [[ -n "$ANALYST_USER" ]] && ! id "$ANALYST_USER" &>/dev/null; then
  echo "Analyst user does not exist: $ANALYST_USER" >&2
  exit 1
fi

install -d -m 0755 "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"
chmod 0640 "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

trap 'echo "ERROR: installation stopped at line $LINENO. Review $LOG_FILE" >&2' ERR

echo "== ubuntu-ops security toolkit =="
echo "OS: ${PRETTY_NAME}"
echo "Profile: ${PROFILE}"
echo "Analyst: ${ANALYST_USER:-not specified}"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends software-properties-common ca-certificates
add-apt-repository -y universe
apt-get update

# Prevent an interactive Wireshark package prompt. Packet capture permissions
# are granted below only to the explicitly selected analyst account.
echo 'wireshark-common wireshark-common/install-setuid boolean true' | debconf-set-selections

CORE_PACKAGES=(
  auditd audispd-plugins aide apparmor-utils clamav clamav-daemon
  curl dnsutils ethtool fail2ban git gnupg iproute2 iputils-ping jq
  libcap2-bin lsof lynis net-tools nmap openssh-client openssl
  pipx python3 python3-venv rsync shellcheck tcpdump traceroute
  tshark ufw unzip whois wireshark yara zip
)

FULL_PACKAGES=(
  arp-scan conntrack entr inotify-tools masscan nikto
  rkhunter sleuthkit sqlite3 suricata testdisk
)

AVAILABLE=()
SKIPPED=()
for package_name in "${CORE_PACKAGES[@]}"; do
  if apt-cache show "$package_name" &>/dev/null; then
    AVAILABLE+=("$package_name")
  else
    SKIPPED+=("$package_name")
  fi
done

if [[ "$PROFILE" == "full" ]]; then
  for package_name in "${FULL_PACKAGES[@]}"; do
    if apt-cache show "$package_name" &>/dev/null; then
      AVAILABLE+=("$package_name")
    else
      SKIPPED+=("$package_name")
    fi
  done
fi

apt-get install -y --no-install-recommends "${AVAILABLE[@]}"

if [[ -n "$ANALYST_USER" ]]; then
  if getent group wireshark &>/dev/null; then
    usermod -aG wireshark "$ANALYST_USER"
  fi
fi

# Enable services that collect or protect local telemetry. Suricata is enabled
# only in the full profile; its monitored interface must still be configured.
for service_name in auditd fail2ban clamav-freshclam; do
  if systemctl list-unit-files "${service_name}.service" --no-legend 2>/dev/null | grep -q .; then
    systemctl enable --now "$service_name" || true
  fi
done

if [[ "$PROFILE" == "full" ]] && command -v suricata &>/dev/null; then
  systemctl enable suricata || true
  echo "NOTE: Suricata installed but requires HOME_NET and interface review before use."
fi

if [[ "$INSTALL_ZAP" == true ]]; then
  if command -v snap &>/dev/null; then
    snap install zaproxy --classic
  else
    echo "SKIP: OWASP ZAP requested, but Snap is unavailable."
  fi
fi

if [[ "$ENABLE_UFW" == true ]]; then
  ufw allow OpenSSH
  ufw --force enable
else
  echo "NOTE: UFW installed but not enabled; review dual-NIC access rules first."
fi

# Initialize AIDE only when its database is absent. This can take several minutes.
if command -v aideinit &>/dev/null && [[ ! -e /var/lib/aide/aide.db ]]; then
  aideinit || echo "WARNING: AIDE initialization did not complete. Run: sudo aideinit"
fi

echo
echo "Installed command check:"
for command_name in auditctl aide clamscan nmap tcpdump tshark wireshark yara lynis shellcheck; do
  if command -v "$command_name" &>/dev/null; then
    printf '  [OK]   %s\n' "$command_name"
  else
    printf '  [INFO] %s not present or uses a different command name\n' "$command_name"
  fi
done

if ((${#SKIPPED[@]})); then
  echo "Packages unavailable for ${VERSION_CODENAME:-this Ubuntu release}: ${SKIPPED[*]}"
fi

cat <<EOF

Installation complete.
Log: $LOG_FILE

Next actions:
  1. Reboot or sign out/in so group membership is refreshed.
  2. Confirm only one NIC has a default gateway: ip route
  3. Keep IPv4 forwarding disabled: sysctl net.ipv4.ip_forward
  4. Configure Security Onion enrollment separately using its current agent policy.
  5. For the full profile, configure Suricata HOME_NET and capture interface.
  6. Run an audit: sudo lynis audit system
EOF
