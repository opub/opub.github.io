
#!/usr/bin/env bash
set -Eeuo pipefail

# Configure a Raspberry Pi as a Tailscale exit node.
#
# Usage:
#   sudo bash setup-exit-node.sh tailscale-exit-node-1
#
# Optional env:
#   TAILSCALE_AUTH_KEY   Reusable auth key (skips browser login and QR).
#   DISABLE_OPENSSH=1    Disable OpenSSH after Tailscale SSH is verified.
#
# Browser login (no auth key): uses --browser=false and shows a QR code via qrencode.
#
# Preconditions:
#   - Raspberry Pi OS Lite / Debian-based OS, network access.
#   - Local console or another recovery path until Tailscale SSH is tested.

log()  { printf '\n[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
fail() { printf '\nERROR: %s\n' "$*" >&2; exit 1; }

# Print the browser login URL and a terminal QR code (scan from phone/laptop).
tailscale_up_with_login_qr() {
  apt-get install -y qrencode

  local fifo qr_shown=0 url
  fifo=$(mktemp -u)
  mkfifo "$fifo"

  tailscale up "$@" --browser=false >"$fifo" 2>&1 &
  local ts_pid=$!

  while IFS= read -r line; do
    printf '%s\n' "$line"
    if [[ "$qr_shown" -eq 0 ]] && [[ "$line" =~ (https://login\.tailscale\.com[^[:space:]]+) ]]; then
      url="${BASH_REMATCH[1]}"
      printf '\n--- Scan to sign in (Tailscale) ---\n'
      if ! qrencode -t ANSIUTF8 "$url" 2>/dev/null \
           && ! qrencode -t UTF8 "$url" 2>/dev/null; then
        qrencode -t ASCII "$url"
      fi
      printf '\nOr open manually:\n%s\n---\n\n' "$url"
      qr_shown=1
    fi
  done <"$fifo"

  wait "$ts_pid" || fail "Tailscale login failed or was interrupted."
  rm -f "$fifo"
}

[[ $EUID -eq 0 ]] || fail "Run with sudo."
[[ $# -eq 1 ]] || fail "Usage: sudo bash $0 <exit-node-name>"

EXIT_NODE_NAME="$1"

# Restrict the name to a simple hostname.
[[ "$EXIT_NODE_NAME" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]] \
  || fail "Invalid hostname: use letters, numbers, and hyphens."

[[ -f /etc/os-release ]] || fail "Cannot identify the operating system."
. /etc/os-release

case "${ID:-}" in
  raspbian|debian) ;;
  *) fail "Expected Raspberry Pi OS or Debian; detected ${PRETTY_NAME:-unknown}." ;;
esac

export DEBIAN_FRONTEND=noninteractive

log "Updating package lists and installing prerequisites."
apt-get update
apt-get install -y curl ca-certificates unattended-upgrades

log "Installing or upgrading Tailscale (stable channel)."
curl -fsSL https://tailscale.com/install.sh | sh

log "Ensuring tailscaled starts automatically on boot."
systemctl enable tailscaled
systemctl start tailscaled
systemctl is-active --quiet tailscaled \
  || fail "tailscaled failed to start."
systemctl is-enabled --quiet tailscaled \
  || fail "tailscaled is not enabled for boot."

log "Enabling IPv4 and IPv6 forwarding for exit-node traffic."
install -d -m 0755 /etc/sysctl.d
cat >/etc/sysctl.d/99-tailscale-exit-node.conf <<'SYSCTL'
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
SYSCTL

sysctl --system

[[ "$(sysctl -n net.ipv4.ip_forward)" == "1" ]] \
  || fail "IPv4 forwarding did not enable."
[[ "$(sysctl -n net.ipv6.conf.all.forwarding)" == "1" ]] \
  || fail "IPv6 forwarding did not enable."

log "Joining tailnet as ${EXIT_NODE_NAME} (SSH + exit node)."
if tailscale status --json 2>/dev/null | grep -q '"BackendState":"Running"'; then
  tailscale set \
    --hostname="$EXIT_NODE_NAME" \
    --ssh \
    --advertise-exit-node \
    --auto-update \
    --stateful-filtering
else
  up_args=(
    --hostname="$EXIT_NODE_NAME"
    --ssh
    --advertise-exit-node
  )
  if [[ -n "${TAILSCALE_AUTH_KEY:-}" ]]; then
    tailscale up "${up_args[@]}" --auth-key="$TAILSCALE_AUTH_KEY"
  else
    log "Waiting for browser login; scan the QR code from another device."
    tailscale_up_with_login_qr "${up_args[@]}"
  fi
  tailscale set --auto-update --stateful-filtering
fi

tailscale status >/dev/null 2>&1 \
  || fail "Tailscale is not connected after setup."

log "Setting timezone to US/Eastern (4:00 automatic reboot uses local time)."
if command -v timedatectl >/dev/null 2>&1; then
  timedatectl set-timezone America/New_York
else
  ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
fi

log "Enabling automatic package-list updates and security upgrades."
cat >/etc/apt/apt.conf.d/20auto-upgrades <<'APT'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
APT

cat >/etc/apt/apt.conf.d/50unattended-upgrades <<'UPGRADES'
Unattended-Upgrade::Allowed-Origins {
	"${distro_id}:${distro_codename}-security";
};

Unattended-Upgrade::Package-Blacklist {
};

Unattended-Upgrade::DevRelease "false";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "04:00";
Unattended-Upgrade::Automatic-Reboot-WithUsers "false";
UPGRADES

systemctl enable --now unattended-upgrades
apt-get install -y --no-install-recommends watchdog
if [[ -f /etc/watchdog.conf ]]; then
  sed -i \
    -e 's/^#watchdog-device/watchdog-device/' \
    -e 's/^#max-load-1/max-load-1/' \
    /etc/watchdog.conf
  systemctl enable --now watchdog 2>/dev/null || true
fi

log "Disabling unused headless services when present."
for unit in bluetooth avahi-daemon; do
  if systemctl list-unit-files "${unit}.service" --no-legend 2>/dev/null \
       | grep -q "${unit}.service"; then
    systemctl disable --now "${unit}.service" 2>/dev/null || true
  fi
done

# OpenSSH is not needed for Tailscale SSH. Leave it alone by default
# to avoid unexpectedly removing an existing recovery path.
if [[ "${DISABLE_OPENSSH:-0}" == "1" ]]; then
  log "Disabling the OpenSSH server as explicitly requested."
  for unit in ssh sshd ssh.socket; do
    if systemctl list-unit-files "${unit}" --no-legend 2>/dev/null \
         | grep -q "${unit}"; then
      systemctl disable --now "${unit}" 2>/dev/null || true
    fi
  done
fi

log "Configuration complete."

printf '\n--- Summary ---\n'
printf 'Hostname:       %s\n' "$EXIT_NODE_NAME"
printf 'Tailscale:      %s\n' "$(tailscale version 2>/dev/null | head -n1)"
printf 'tailscaled:     %s (boot)\n' "$(systemctl is-enabled tailscaled)"
printf 'Tailscale IPv4: %s\n' "$(tailscale ip -4 | head -n1)"
printf 'Tailscale SSH:  enabled\n'
printf 'Exit node:      advertised\n'
printf 'Auto-updates:   security-only, reboot 04:00 America/New_York\n'
printf 'Timezone:       %s\n' "$(readlink -f /etc/localtime 2>/dev/null || date +%Z)"
printf 'IPv4 forwarding: %s\n' "$(sysctl -n net.ipv4.ip_forward)"
printf 'IPv6 forwarding: %s\n' "$(sysctl -n net.ipv6.conf.all.forwarding)"
printf '\nTailscale status:\n'
tailscale status

cat <<'NEXT'

Next steps:
  1. In the Tailscale admin console, approve this device as an exit node.
  2. Confirm your tailnet access policy permits your identity to use
     Tailscale SSH to this machine as the intended Linux user.
  3. From your Mac, test:
       ssh <linux-username>@<tailscale-hostname>
     Use the hostname with your tailnet's MagicDNS domain if needed.
  4. Test exit-node traffic and verify the public IP is the home's ISP IP.
  5. Reboot the Pi and verify that it reconnects successfully.

The script does not modify router port forwarding or add firewall rules.
NEXT
