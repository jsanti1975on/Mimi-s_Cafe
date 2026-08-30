#!/usr/bin/env bash

set -Eeuo pipefail

HOST_FQDN="enter-fqdn.local"
EXPECTED_IP="0.0.0.0"
EXPECTED_GATEWAY="0.0.0.0"
TARGET_RELEASE="9.8"
LOG_FILE="/var/log/rhel-dns01-startup.log"

if [[ $EUID -ne 0 ]]; then
    echo "Run with sudo:"
    echo "sudo $0"
    exit 1
fi

exec > >(tee -a "$LOG_FILE") 2>&1

echo "========================================"
echo " RHEL DNS Server Initial Configuration"
echo "========================================"
echo
echo "Hostname: $HOST_FQDN"
echo "Expected IP: $EXPECTED_IP"
echo "Gateway: $EXPECTED_GATEWAY"
echo "Target release: RHEL $TARGET_RELEASE"
echo

read -r -p "Ready to begin? Type yes: " READY

if [[ "$READY" != "yes" ]]; then
    echo "Operation cancelled."
    exit 0
fi

echo
echo "[1/10] Displaying system information..."
cat /etc/redhat-release
uname -r

echo
echo "[2/10] Setting hostname..."
hostnamectl set-hostname "$HOST_FQDN"
hostnamectl --static

echo
echo "[3/10] Checking network configuration..."
ip -brief address
ip route

if ip -4 address show | grep -q "$EXPECTED_IP"; then
    echo "PASS: Expected IP address detected."
else
    echo "WARNING: Expected IP $EXPECTED_IP was not detected."
fi

if ip route | grep -q "default via $EXPECTED_GATEWAY"; then
    echo "PASS: Expected gateway detected."
else
    echo "WARNING: Expected gateway was not detected."
fi

echo
echo "[4/10] Checking Red Hat subscription..."
subscription-manager status || true
subscription-manager identity || true

echo
echo "[5/10] Pinning the RHEL release..."

if subscription-manager release --list |
    grep -qx "$TARGET_RELEASE"; then

    subscription-manager release --set="$TARGET_RELEASE"
else
    echo "WARNING: RHEL $TARGET_RELEASE is not available."
    echo "The release was not changed."
fi

subscription-manager release --show || true

echo
echo "[6/10] Refreshing repositories..."
dnf clean all
dnf makecache

echo
echo "[7/10] Updating installed packages..."
dnf upgrade --refresh -y

echo
echo "[8/10] Installing server packages..."
dnf install -y \
    bind \
    bind-utils \
    chrony \
    cockpit \
    open-vm-tools \
    policycoreutils-python-utils \
    vim-enhanced \
    bash-completion \
    curl \
    wget \
    tar

echo
echo "[9/10] Enabling infrastructure services..."
systemctl enable --now chronyd
systemctl enable --now vmtoolsd
systemctl enable --now cockpit.socket

echo
echo "[10/10] Configuring the firewall..."
firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-service=cockpit
firewall-cmd --reload

echo
echo "Checking SELinux..."
getenforce
sestatus

echo
echo "Checking time synchronization..."
timedatectl
chronyc tracking || true

echo
echo "Checking installed BIND version..."
named -v

echo
echo "========================================"
echo " Initial configuration complete"
echo "========================================"
echo
echo "BIND is installed but has not been started."
echo "DNS port 53 has not been opened yet."
echo "We will configure and validate named.conf first."
echo
echo "Cockpit:"
echo "https://$EXPECTED_IP:9090"
echo
echo "Log file:"
echo "$LOG_FILE"
echo
echo "Reboot after reviewing the results."
