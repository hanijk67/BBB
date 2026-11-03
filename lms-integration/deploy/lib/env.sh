#!/usr/bin/env bash
# کتابخانه‌ی مشترک: load کردن .env و اعتبارسنجی متغیرها.
# استفاده: source lib/env.sh; load_env [path]; require_vars VAR1 VAR2 ...
# (این فایل source می‌شود؛ set -euo pipefail در اسکریپت صدازننده است)

# لاگ با پیشوند خوانا
log()  { printf '\033[1;34m[*]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[✓]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[✗] خطا:\033[0m %s\n' "$*" >&2; exit 1; }

# load_env [path] — پیش‌فرض: .env کنار پوشه‌ی deploy
load_env() {
  local env_file="${1:-${LMS_ENV_FILE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.env}}"
  [[ -f "$env_file" ]] || die "فایل .env پیدا نشد: $env_file (از .env.example کپی کنید)"
  # CRLF در .env (ادیت روی ویندوز) مقدارها را خراب می‌کند
  if grep -q $'\r' "$env_file"; then
    die "فایل $env_file پایان خط ویندوزی (CRLF) دارد؛ با dos2unix تبدیل کنید"
  fi
  set -a
  # shellcheck disable=SC1090
  . "$env_file"
  set +a
  LMS_ENV_FILE="$env_file"
  export LMS_ENV_FILE
}

# require_vars VAR... — اگر هر کدام خالی بود، همه را گزارش و exit 1
require_vars() {
  local missing=() v
  for v in "$@"; do
    [[ -n "${!v:-}" ]] || missing+=("$v")
  done
  if ((${#missing[@]})); then
    die "این متغیرها در .env خالی هستند: ${missing[*]}"
  fi
}

# require_root — اسکریپت‌های نصب باید با root اجرا شوند
require_root() {
  [[ "${EUID:-$(id -u)}" -eq 0 ]] || die "این اسکریپت باید با root (sudo) اجرا شود"
}

# validate_turn_secret — طول ۸ تا ۱۶ و فقط حرف/عدد (bbb-install مقدار را با ':' جدا می‌کند)
validate_turn_secret() {
  local s="${BBB_TURN_SECRET:-}"
  ((${#s} >= 8 && ${#s} <= 16)) || die "طول BBB_TURN_SECRET باید بین ۸ تا ۱۶ کاراکتر باشد (الان ${#s})"
  [[ "$s" =~ ^[A-Za-z0-9]+$ ]] || die "BBB_TURN_SECRET فقط باید حرف انگلیسی و عدد باشد"
}

# fetch_bbb_install DEST — دانلود bbb-install.sh از برنچ تعیین‌شده
fetch_bbb_install() {
  local dest="$1" branch="${BBB_INSTALL_BRANCH:-v4.0.x-release}"
  local url="https://raw.githubusercontent.com/bigbluebutton/bbb-install/${branch}/bbb-install.sh"
  log "دانلود bbb-install.sh از برنچ $branch"
  curl -fsSL --retry 3 -o "$dest" "$url" || die "دانلود $url ناموفق بود"
  head -1 "$dest" | grep -q '^#!' || die "فایل دانلودشده اسکریپت معتبر نیست: $dest"
  chmod +x "$dest"
}

# resolve_a HOST — IPv4 های رکورد A
resolve_a() {
  if command -v dig >/dev/null 2>&1; then
    dig +short A "$1" | grep -E '^[0-9.]+$' || true
  else
    getent ahostsv4 "$1" | awk '{print $1}' | sort -u || true
  fi
}

# public_ipv4 — IP عمومی همین سرور
public_ipv4() {
  curl -fsS4 --max-time 5 https://api.ipify.org 2>/dev/null \
    || hostname -I 2>/dev/null | awk '{print $1}'
}
