#!/usr/bin/env bash
# تست سرور TURN از بیرون (از لپ‌تاپ یا سرور BBB، نه خود سرور TURN).
# استفاده: tools/check-turn.sh [path/to/.env]  یا  BBB_TURN_HOST=turn.glmp.ir tools/check-turn.sh
set -euo pipefail

DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/env.sh
. "$DEPLOY_DIR/lib/env.sh"

if [[ -z "${BBB_TURN_HOST:-}" ]]; then
  load_env "${1:-}"
fi
require_vars BBB_TURN_HOST
command -v nc >/dev/null 2>&1 || die "nc (netcat) نصب نیست: apt install netcat-openbsd"

fail=0
check() { # check <label> <cmd...>
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then ok "PASS  $label"; else warn "FAIL  $label"; fail=1; fi
}

log "DNS: $BBB_TURN_HOST → $(resolve_a "$BBB_TURN_HOST" | tr '\n' ' ')"
check "3478/tcp" nc -vz -w 5 "$BBB_TURN_HOST" 3478
check "443/tcp"  nc -vz -w 5 "$BBB_TURN_HOST" 443
# UDP پاسخ قطعی ندارد: nc -u فقط «رد نشدن صریح» را نشان می‌دهد
check "3478/udp (تقریبی)" nc -vzu -w 3 "$BBB_TURN_HOST" 3478

# گواهی TLS معتبر روی 443
if command -v openssl >/dev/null 2>&1; then
  if echo | openssl s_client -connect "$BBB_TURN_HOST:443" -servername "$BBB_TURN_HOST" \
       -verify_return_error 2>/dev/null | grep -q 'Verify return code: 0 (ok)'; then
    ok "PASS  گواهی TLS روی 443 معتبر است"
  else
    warn "FAIL  گواهی TLS روی 443 معتبر نیست یا TLS پاسخ نمی‌دهد"; fail=1
  fi
fi

cat <<'GUIDE'

راهنمای تست relay (بعد از نصب BBB با -c):
  1) Firefox: در about:config مقدار media.peerconnection.ice.relay_only را true کنید
     (یا از شبکه‌ای وارد شوید که UDP خروجی‌اش بسته است).
  2) وارد یک کلاس تستی روی BBB شوید و میکروفون/وبکم را روشن کنید.
  3) Firefox: about:webrtc → در ICE candidates کاندید نوع «relay» با آدرس سرور TURN و حالت
     succeeded دیده شود. Chrome: chrome://webrtc-internals → candidate-pair با candidateType=relay.
  4) سناریوی واقعی: کاربری روی اینترنت موبایل یا با UDP خروجی بسته صدا/تصویر بگیرد.
  5) بعد از تست relay_only را به false برگردانید.
GUIDE

exit "$fail"
