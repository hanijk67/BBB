#!/usr/bin/env bash
# مانیتورینگ حداقلی سرور BBB — فاز ۷: دیسک ضبط، بار CPU، API، صف پردازش ضبط.
# روی سرور BBB:  tools/health-check.sh [path/to/.env]
# هر مشکل یک خط در syslog (tag bbb-health) و stderr؛ اگر BBB_ALERT_WEBHOOK ست باشد، پیام JSON
# {"text": "..."} به آن POST می‌شود. کد خروج: 0 سالم، 1 هشدار.
#
# نمونه‌ی cron (هر ۵ دقیقه):
#   */5 * * * * root /etc/bigbluebutton/lms/tools/health-check.sh >/dev/null 2>&1
#
# برای مانیتورینگ کامل‌تر (Prometheus/Grafana) bbb-exporter پیشنهاد می‌شود — README.
set -euo pipefail

TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="$TOOLS_DIR/../lib/env.sh"
[[ -f "$LIB" ]] || LIB=/etc/bigbluebutton/lms/lib/env.sh
# shellcheck source=../lib/env.sh
. "$LIB"

ENV_FILE="${1:-}"
if [[ -z "$ENV_FILE" && -f /etc/bigbluebutton/lms/.env ]]; then ENV_FILE=/etc/bigbluebutton/lms/.env; fi
load_env "$ENV_FILE"
require_vars BBB_DOMAIN

DISK_PCT="${BBB_ALERT_DISK_PCT:-85}"
LOAD_PER_CPU="${BBB_ALERT_LOAD_PER_CPU:-1.5}"
QUEUE_MAX="${BBB_ALERT_RECORDING_QUEUE:-10}"

problems=()
alert() { problems+=("$*"); warn "$*"; logger -t bbb-health -- "$*" 2>/dev/null || true; }

# --- دیسک ضبط ---
used="$(df -P /var/bigbluebutton | awk 'NR==2 {gsub("%","",$5); print $5}')"
if ((used >= DISK_PCT)); then
  alert "دیسک ضبط ${used}% پر است (آستانه ${DISK_PCT}%)"
else
  ok "دیسک ضبط ${used}%"
fi

# --- بار CPU (load average ۵ دقیقه به ازای هر هسته) ---
cpus="$(nproc)"
load5="$(awk '{print $2}' /proc/loadavg)"
if awk -v l="$load5" -v c="$cpus" -v t="$LOAD_PER_CPU" 'BEGIN {exit !(l / c > t)}'; then
  alert "بار CPU بالا: load5=$load5 روی $cpus هسته"
else
  ok "load5=$load5 / $cpus هسته"
fi

# --- API ---
api="https://${BBB_DOMAIN}/bigbluebutton/api"
if curl -fsS --max-time 10 "$api" | grep -q '<returncode>SUCCESS</returncode>'; then
  ok "API پاسخ SUCCESS"
else
  alert "API ($api) پاسخ SUCCESS نداد"
fi

# --- سرویس‌های اصلی ---
for unit in bbb-web bbb-html5 nginx freeswitch bbb-rap-resque-worker; do
  if systemctl list-unit-files "$unit.service" >/dev/null 2>&1 && ! systemctl is-active --quiet "$unit"; then
    alert "سرویس $unit فعال نیست"
  fi
done

# --- صف پردازش ضبط: ضبط‌هایی که archive شده‌اند ولی هنوز published نیستند ---
status_dir=/var/bigbluebutton/recording/status
if [[ -d "$status_dir/archived" ]]; then
  pending=0
  for f in "$status_dir"/archived/*.done; do
    [[ -e "$f" ]] || continue
    id="$(basename "$f" .done)"
    compgen -G "$status_dir/published/${id}-*.done" >/dev/null || pending=$((pending + 1))
  done
  if ((pending > QUEUE_MAX)); then
    alert "صف پردازش ضبط: $pending ضبط منتظر انتشار (آستانه $QUEUE_MAX)"
  else
    ok "صف پردازش ضبط: $pending"
  fi
fi

if ((${#problems[@]})); then
  if [[ -n "${BBB_ALERT_WEBHOOK:-}" ]]; then
    text="[$BBB_DOMAIN] $(printf '%s; ' "${problems[@]}")"
    payload="$(TEXT="$text" python3 -c 'import json,os; print(json.dumps({"text": os.environ["TEXT"]}))')"
    curl -fsS --max-time 10 -H 'Content-Type: application/json' -d "$payload" "$BBB_ALERT_WEBHOOK" >/dev/null \
      || warn "ارسال هشدار به webhook ناموفق بود"
  fi
  exit 1
fi
exit 0
