#!/usr/bin/env bash

set -o pipefail

scan_report="$HOME/rhel-gpg-key-report.txt"
scan_raw="$(mktemp)"
trap 'rm -f "$scan_raw"' EXIT

printf '\nRHEL Cached-Package GPG Key Locator\n'
printf '%s\n\n' '-----------------------------------'

read -r -p "Ready to locate the failed GPG key? Enter yes to continue: " ready_answer

case "${ready_answer,,}" in
    yes|y)
        printf '\nPhase 1: Requesting administrative access...\n'
        if ! sudo -v; then
            printf 'Administrative authentication failed. No scan was performed.\n' >&2
            exit 1
        fi

        printf 'Phase 2: Checking cached RPM signatures...\n'
        sudo find /var/cache/dnf -type f -name '*.rpm' \
            -exec rpmkeys --checksig -v {} \; >"$scan_raw" 2>&1

        printf '\n=== PACKAGES WITH MISSING KEYS ===\n' | tee "$scan_report"

        awk '
            /\.rpm:$/ { package = $0 }
            /NOKEY/ {
                print package
                print "  " $0
                print ""
                found = 1
            }
            END { if (!found) exit 2 }
        ' "$scan_raw" | tee -a "$scan_report"
        awk_status=${PIPESTATUS[0]}

        if [[ $awk_status -eq 2 ]]; then
            printf 'No cached RPM packages reported a missing key.\n' | tee -a "$scan_report"
        elif [[ $awk_status -ne 0 ]]; then
            printf 'The signature scan could not be parsed.\n' >&2
            exit 1
        fi

        printf '\n=== UNIQUE MISSING KEY IDs ===\n' | tee -a "$scan_report"
        missing_keys="$({
            grep -oiE 'key ID [[:xdigit:]]+: NOKEY' "$scan_raw" || true
        } | awk '{print toupper($3)}' | tr -d ':' | sort -u)"

        if [[ -n "$missing_keys" ]]; then
            printf '%s\n' "$missing_keys" | tee -a "$scan_report"
        else
            printf 'None detected.\n' | tee -a "$scan_report"
        fi

        printf '\nScan complete. Report saved to:\n%s\n' "$scan_report"
        ;;
    *)
        printf '\nScan cancelled. No changes were made.\n'
        exit 0
        ;;
esac
