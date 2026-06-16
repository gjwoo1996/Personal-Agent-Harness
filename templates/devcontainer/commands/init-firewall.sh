#!/usr/bin/env bash
# Optional devcontainer firewall example. Wire into postStartCommand only after
# first-time package and browser downloads are complete.
set -euo pipefail

warn() {
  echo "WARN: $*" >&2
}

if ! command -v iptables >/dev/null 2>&1 || ! command -v ipset >/dev/null 2>&1; then
  warn "iptables or ipset unavailable; firewall not applied"
  exit 0
fi

if [ "$(id -u)" -ne 0 ] && ! command -v sudo >/dev/null 2>&1; then
  warn "sudo unavailable; firewall not applied"
  exit 0
fi

run() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

SET_NAME="devcontainer_allowed_hosts"
DOMAINS=(
  github.com
  api.github.com
  raw.githubusercontent.com
  objects.githubusercontent.com
  registry.npmjs.org
  npmjs.org
  anthropic.com
  api.anthropic.com
  console.anthropic.com
  openai.com
  api.openai.com
  bun.sh
  github-releases.githubusercontent.com
  playwright.azureedge.net
  storage.googleapis.com
  edgedl.me.gvt1.com
)

run ipset create "$SET_NAME" hash:ip -exist

for domain in "${DOMAINS[@]}"; do
  while read -r ip; do
    [ -n "$ip" ] && run ipset add "$SET_NAME" "$ip" -exist
  done < <(getent ahostsv4 "$domain" | awk '{print $1}' | sort -u || true)
done

run iptables -C OUTPUT -o lo -j ACCEPT 2>/dev/null || run iptables -A OUTPUT -o lo -j ACCEPT
run iptables -C OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || run iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
run iptables -C OUTPUT -p udp --dport 53 -j ACCEPT 2>/dev/null || run iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
run iptables -C OUTPUT -p tcp --dport 53 -j ACCEPT 2>/dev/null || run iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
run iptables -C OUTPUT -p tcp -m set --match-set "$SET_NAME" dst -m multiport --dports 80,443 -j ACCEPT 2>/dev/null || run iptables -A OUTPUT -p tcp -m set --match-set "$SET_NAME" dst -m multiport --dports 80,443 -j ACCEPT

echo "Firewall initialized with allowlist: $SET_NAME"
