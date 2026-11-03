#!/usr/bin/env bash
# نصب/آپدیت BigBlueButton با پیکربندی از .env — فاز ۲ (T1، T2).
# روی سرور BBB اجرا شود:  sudo ./install.sh [path/to/.env]
# هر مرحله قابل اجرای مجدد است؛ برای آپدیت BBB هم همین اسکریپت را دوباره اجرا کنید.
set -euo pipefail

DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/env.sh
. "$DEPLOY_DIR/lib/env.sh"

LMS_ETC=/etc/bigbluebutton/lms          # کپی ثابت .env و overrides که apply-config.sh می‌خواند
APPLY_CONFIG=/etc/bigbluebutton/bbb-conf/apply-config.sh
BBB_DATA=/var/bigbluebutton

require_root
load_env "${1:-}"
require_vars BBB_DOMAIN BBB_LETSENCRYPT_EMAIL BBB_VERSION BBB_SHARED_SECRET \
             BBB_TURN_HOST BBB_TURN_SECRET BBB_RECORDINGS_DIR
validate_turn_secret
[[ "$BBB_SHARED_SECRET" != 330a8b08c3b4c61533e1d0c5ce1ac88f ]] \
  || die "BBB_SHARED_SECRET نباید secret پیش‌فرض سورس باشد؛ openssl rand -hex 32"
((${#BBB_SHARED_SECRET} >= 32)) || die "BBB_SHARED_SECRET حداقل ۳۲ کاراکتر باشد (openssl rand -hex 32)"
[[ -f "$DEPLOY_DIR/apply-config.sh" ]] \
  || die "فایل $DEPLOY_DIR/apply-config.sh وجود ندارد (تسک 04)؛ نصب متوقف شد"

# --- ۱) preflight ---
log "مرحله ۱: چک‌های پیش از نصب"
"$DEPLOY_DIR/tools/preflight.sh" "$LMS_ENV_FILE" || die "preflight رد شد؛ موارد FAIL را رفع کنید"

# --- ۲) registry mirror برای Docker (merge، نه overwrite) ---
if [[ -n "${DOCKER_REGISTRY_MIRROR:-}" ]]; then
  log "مرحله ۲: افزودن $DOCKER_REGISTRY_MIRROR به /etc/docker/daemon.json"
  mkdir -p /etc/docker
  changed="$(DOCKER_REGISTRY_MIRROR="$DOCKER_REGISTRY_MIRROR" python3 - <<'PY'
import json, os
path = "/etc/docker/daemon.json"
mirror = os.environ["DOCKER_REGISTRY_MIRROR"]
data = {}
if os.path.exists(path):
    with open(path, encoding="utf-8") as f:
        text = f.read().strip()
    data = json.loads(text) if text else {}
mirrors = data.setdefault("registry-mirrors", [])
if mirror in mirrors:
    print("no")
else:
    mirrors.append(mirror)
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    os.replace(tmp, path)
    print("yes")
PY
)"
  if [[ "$changed" == yes ]]; then
    systemctl is-active --quiet docker && systemctl restart docker
    ok "mirror اضافه شد"
  else
    ok "mirror از قبل در daemon.json هست"
  fi
else
  log "مرحله ۲: DOCKER_REGISTRY_MIRROR خالی است — رد شد"
fi

# --- ۳) bbb-install.sh (بدون -g؛ رابط کاربری ما LMS است) ---
log "مرحله ۳: اجرای bbb-install.sh -v $BBB_VERSION -s $BBB_DOMAIN"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
fetch_bbb_install "$WORK_DIR/bbb-install.sh"
"$WORK_DIR/bbb-install.sh" -v "$BBB_VERSION" -s "$BBB_DOMAIN" -e "$BBB_LETSENCRYPT_EMAIL" \
  -c "$BBB_TURN_HOST:$BBB_TURN_SECRET"
ok "bbb-install.sh تمام شد"

# --- ۴) /var/bigbluebutton روی BBB_RECORDINGS_DIR (bind mount) ---
log "مرحله ۴: مسیر ضبط → $BBB_RECORDINGS_DIR"
target="$(realpath -m "$BBB_RECORDINGS_DIR")"
fstab_line="$target $BBB_DATA none bind 0 0"
if [[ "$target" == "$BBB_DATA" ]]; then
  ok "BBB_RECORDINGS_DIR همان $BBB_DATA است — جابه‌جایی لازم نیست"
elif mountpoint -q "$BBB_DATA" && [[ -d "$target" ]] \
     && [[ "$(stat -c %d:%i "$BBB_DATA")" == "$(stat -c %d:%i "$target")" ]]; then
  # bind mount: هر دو مسیر به یک inode اشاره می‌کنند
  ok "$BBB_DATA از قبل روی $target mount است"
  grep -qxF "$fstab_line" /etc/fstab || { echo "$fstab_line" >> /etc/fstab; ok "خط fstab اضافه شد"; }
else
  mountpoint -q "$BBB_DATA" && die "$BBB_DATA روی مسیر دیگری mount است؛ دستی بررسی کنید (findmnt $BBB_DATA)"
  mkdir -p "$target"
  need_kb="$(du -sk "$BBB_DATA" | awk '{print $1}')"
  free_kb="$(df -Pk "$target" | awk 'NR==2 {print $4}')"
  ((free_kb > need_kb * 11 / 10)) \
    || die "فضای آزاد $target (${free_kb}KB) برای کپی $BBB_DATA (${need_kb}KB) کافی نیست"
  ok "فضای دیسک مقصد کافی است (${free_kb}KB آزاد، ${need_kb}KB لازم)"

  bbb-conf --stop
  rsync -a "$BBB_DATA"/ "$target"/
  backup="$BBB_DATA.orig"
  [[ -e "$backup" ]] && backup="$BBB_DATA.orig.$(date +%Y%m%d%H%M%S)"
  mv "$BBB_DATA" "$backup"
  mkdir "$BBB_DATA"
  grep -qxF "$fstab_line" /etc/fstab || echo "$fstab_line" >> /etc/fstab
  mount "$BBB_DATA"
  ok "$BBB_DATA روی $target mount شد (نسخه‌ی قبلی: $backup — بعد از تأیید پاک کنید)"
fi

# --- ۵) کپی .env/overrides و نصب apply-config.sh ---
log "مرحله ۵: نصب apply-config.sh و فایل‌های override در $LMS_ETC"
install -d -m 750 "$LMS_ETC" "$LMS_ETC/lib" "$LMS_ETC/tools"
install -m 600 "$LMS_ENV_FILE" "$LMS_ETC/.env"
install -m 644 "$DEPLOY_DIR/lib/env.sh" "$LMS_ETC/lib/env.sh"
# ابزارهای cron (backup، health-check) از مسیر ثابت اجرا می‌شوند
install -m 755 "$DEPLOY_DIR"/tools/backup.sh "$DEPLOY_DIR"/tools/health-check.sh \
  "$DEPLOY_DIR"/tools/measure-recording.sh "$LMS_ETC/tools/"
rsync -a --delete --exclude '.gitkeep' "$DEPLOY_DIR/overrides/" "$LMS_ETC/overrides/"
if [[ -f "$APPLY_CONFIG" ]] && ! grep -q 'LMS-APPLY-CONFIG' "$APPLY_CONFIG"; then
  cp -a "$APPLY_CONFIG" "$APPLY_CONFIG.bbb-default.bak"
  warn "apply-config.sh قبلی در $APPLY_CONFIG.bbb-default.bak نگه داشته شد"
fi
install -m 755 "$DEPLOY_DIR/apply-config.sh" "$APPLY_CONFIG"
ok "apply-config.sh نصب شد"

# --- ۶) restart و check ---
log "مرحله ۶: bbb-conf --restart (apply-config.sh خودکار اجرا می‌شود)"
bbb-conf --restart
bbb-conf --check || warn "bbb-conf --check هشدار داد؛ خروجی بالا را بررسی کنید"
ok "نصب تمام شد: https://$BBB_DOMAIN/bigbluebutton/api"
