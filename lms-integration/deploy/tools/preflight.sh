#!/usr/bin/env bash
# چک‌های فاز ۱ قبل از نصب BBB (روی سرور BBB اجرا شود).
# استفاده: sudo tools/preflight.sh [path/to/.env]
# خروجی: هر چک PASS / WARN / FAIL؛ اگر حداقل یک FAIL باشد exit 1.
set -euo pipefail

DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/env.sh
. "$DEPLOY_DIR/lib/env.sh"

load_env "${1:-}"
require_vars BBB_DOMAIN

fails=0
warns=0
pass()  { printf '\033[1;32mPASS\033[0m  %s\n' "$*"; }
wfail() { printf '\033[1;33mWARN\033[0m  %s\n' "$*"; warns=$((warns + 1)); }
fail()  { printf '\033[1;31mFAIL\033[0m  %s\n' "$*"; fails=$((fails + 1)); }

# اگر BBB قبلاً نصب شده (اجرای مجدد install.sh)، اشغال بودن 80/443 توسط خود BBB طبیعی است
bbb_installed=false
dpkg -s bbb-config >/dev/null 2>&1 && bbb_installed=true

echo "=== چک‌های پیش از نصب BBB برای $BBB_DOMAIN ==="

# --- سیستم‌عامل و کرنل ---
# shellcheck disable=SC1091
. /etc/os-release
if [[ "${ID:-}" == "ubuntu" && "${VERSION_ID:-}" == "24.04" ]]; then
  pass "سیستم‌عامل: $PRETTY_NAME"
else
  fail "سیستم‌عامل باید Ubuntu 24.04 باشد (الان: ${PRETTY_NAME:-نامشخص})"
fi
[[ "$(uname -m)" == "x86_64" ]] && pass "معماری: x86_64" || fail "معماری باید x86_64 باشد (الان: $(uname -m))"
kernel="$(uname -r)"
[[ "$kernel" == 6.* ]] && pass "کرنل: $kernel" || fail "کرنل باید 6.x باشد (الان: $kernel)"

# --- CPU و RAM ---
cpus="$(nproc --all)"
if ((cpus >= 8)); then pass "CPU: $cpus هسته"
elif ((cpus >= 4)); then wfail "CPU: $cpus هسته — فقط برای تست؛ production حداقل 8"
else fail "CPU: $cpus هسته — حداقل 4 (production: 8)"; fi

mem_gb="$(awk '/MemTotal/ {printf "%d", $2/1024/1024 + 0.5}' /proc/meminfo)"
if ((mem_gb >= 15)); then pass "RAM: ${mem_gb}G"
elif ((mem_gb >= 8)); then wfail "RAM: ${mem_gb}G — فقط برای تست؛ production حداقل 16G"
else fail "RAM: ${mem_gb}G — حداقل 8G (production: 16G)"; fi
free -h | sed 's/^/      /'
swap_kb="$(awk '/SwapTotal/ {print $2}' /proc/meminfo)"
((swap_kb > 0)) && pass "swap فعال است" || wfail "swap تعریف نشده"

# --- IPv6 loopback ---
if ip -6 addr show lo 2>/dev/null | grep -q 'inet6 ::1/128'; then
  pass "IPv6 loopback (::1) موجود است"
else
  wfail "inet6 ::1/128 نیست — بعد از نصب IPv6 را در FreeSWITCH خاموش کنید (مستند troubleshooting)"
fi

# --- DNS ---
my_ip="${BBB_PUBLIC_IP:-$(public_ipv4)}"
dns_ips="$(resolve_a "$BBB_DOMAIN" | tr '\n' ' ')"
if [[ -z "$dns_ips" ]]; then
  fail "DNS: $BBB_DOMAIN رکورد A ندارد"
elif grep -qw "$my_ip" <<<"$dns_ips"; then
  pass "DNS: $BBB_DOMAIN → $my_ip"
else
  fail "DNS: $BBB_DOMAIN → $dns_ips ولی IP این سرور $my_ip است"
fi

# --- پورت‌های 80 و 443 ---
for port in 80 443; do
  listener="$(ss -Hltnp "sport = :$port" 2>/dev/null || true)"
  if [[ -z "$listener" ]]; then
    pass "پورت $port آزاد است"
  elif $bbb_installed && grep -qE 'nginx|haproxy' <<<"$listener"; then
    pass "پورت $port در اختیار BBB است (اجرای مجدد)"
  else
    fail "پورت $port اشغال است: $(awk '{print $NF}' <<<"$listener" | head -1)"
  fi
done
if dpkg -s apache2-bin >/dev/null 2>&1; then fail "apache2 نصب است (bbb-install خطا می‌دهد)"; fi

# --- دسترسی شبکه (ایران) ---
reach() { # reach <label> <url>
  if curl -fsS -o /dev/null --max-time 15 "$2" 2>/dev/null \
     || curl -sS -o /dev/null --max-time 15 -w '%{http_code}' "$2" 2>/dev/null | grep -qE '^[1-4][0-9][0-9]$'; then
    pass "دسترسی به $1"
  else
    fail "دسترسی به $1 ($2) برقرار نیست"
  fi
}
reach "مخزن پکیج BBB" "https://ubuntu.bigbluebutton.org/"
reach "GitHub (bbb-install.sh)" "https://raw.githubusercontent.com/bigbluebutton/bbb-install/${BBB_INSTALL_BRANCH:-v4.0.x-release}/README.md"
reach "Let's Encrypt" "https://acme-v02.api.letsencrypt.org/directory"
if [[ -n "${DOCKER_REGISTRY_MIRROR:-}" ]]; then
  reach "Docker registry mirror" "${DOCKER_REGISTRY_MIRROR%/}/v2/"
else
  # پاسخ 401 از registry یعنی در دسترس است
  code="$(curl -sS -o /dev/null --max-time 15 -w '%{http_code}' https://registry-1.docker.io/v2/ 2>/dev/null || true)"
  if [[ "$code" == "401" || "$code" == "200" ]]; then
    pass "دسترسی به Docker Hub"
  else
    fail "Docker Hub در دسترس نیست (کد: ${code:-ندارد}) — DOCKER_REGISTRY_MIRROR را در .env ست کنید"
  fi
fi

echo "=== نتیجه: $fails FAIL، $warns WARN ==="
((fails == 0))
