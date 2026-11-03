#!/usr/bin/env bash
# LMS-APPLY-CONFIG — سفارشی‌سازی‌های BBB برای LMS (T2).
# نصب در /etc/bigbluebutton/bbb-conf/apply-config.sh (توسط install.sh). bbb-conf این فایل را
# بعد از هر آپدیت پکیج / bbb-install.sh / bbb-conf --restart، درست قبل از start سرویس‌ها اجرا
# می‌کند (bigbluebutton-config/bin/bbb-conf). پس هیچ فایلی روی سرور دستی ادیت نمی‌شود.
# خودکفا: .env و overrides را از /etc/bigbluebutton/lms می‌خواند. همه‌ی مراحل idempotent.
# اینجا bbb-conf --restart صدا زده نشود (حلقه‌ی بی‌نهایت).
set -euo pipefail

LMS_ETC="${LMS_ETC:-/etc/bigbluebutton/lms}"
OVR="$LMS_ETC/overrides"
# shellcheck source=lib/env.sh
. "$LMS_ETC/lib/env.sh"
load_env "$LMS_ETC/.env"
require_vars BBB_DOMAIN BBB_SHARED_SECRET

WEB_PROPS=/etc/bigbluebutton/bbb-web.properties
WEB_PROPS_DEFAULT=/usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties
HTML5_CONFIG=/etc/bigbluebutton/bbb-html5.yml
HTML5_DIR=/usr/share/bigbluebutton/html5-client
REC_OVERRIDE=/etc/bigbluebutton/recording/recording.yml
SCRIPTS_DIR=/usr/local/bigbluebutton/core/scripts
ASSETS_ROOT=/var/www/bigbluebutton-default/assets   # root در nginx سایت bigbluebutton (location /)
CRON_CONFIG=/etc/default/bigbluebutton-cron-config  # cron.daily/bigbluebutton این را source می‌کند

echo "=== apply-config.sh (LMS) ==="

# --- فایروال: همان کاری که apply-config پیش‌فرض bbb-install.sh انجام می‌داد ---
# shellcheck disable=SC1091
. /etc/bigbluebutton/bbb-conf/apply-lib.sh
enableUFWRules

# set_prop KEY VALUE FILE — مقدار یک کلید properties را ست کن (اضافه یا جایگزین)
set_prop() {
  local key="$1" value="$2" file="$3" tmp
  touch "$file"
  if grep -q "^${key}=" "$file"; then
    [[ "$(grep -m1 "^${key}=" "$file" | cut -d= -f2-)" == "$value" ]] && return 0
    tmp="$(mktemp)"
    K="$key" V="$value" awk 'index($0, ENVIRON["K"] "=") == 1 { print ENVIRON["K"] "=" ENVIRON["V"]; next } { print }' \
      "$file" > "$tmp"
    cat "$tmp" > "$file"; rm -f "$tmp"
  else
    printf '%s=%s\n' "$key" "$value" >> "$file"
  fi
}

# copy_if_changed SRC DEST — فقط اگر فرق دارد کپی کن؛ خروجی 0 = کپی شد
copy_if_changed() {
  cmp -s "$1" "$2" 2>/dev/null && return 1
  install -D -m 644 "$1" "$2"
}

# --- ۱) bbb-web.properties ---
log "۱) bbb-web.properties: secret، مهمان، ضبط، اعلان ضبط"
set_prop securitySalt "$BBB_SHARED_SECRET" "$WEB_PROPS"
set_prop defaultGuestPolicy "${BBB_DEFAULT_GUEST_POLICY:-ALWAYS_ACCEPT}" "$WEB_PROPS"
set_prop disableRecordingDefault false "$WEB_PROPS"
set_prop autoStartRecording false "$WEB_PROPS"
set_prop allowStartStopRecording true "$WEB_PROPS"
set_prop notifyRecordingIsOn true "$WEB_PROPS"
if [[ -n "${BBB_ALLOWED_CALLBACK_HOSTS:-}" ]]; then
  set_prop fetchUrlAllowedLocalHosts "$BBB_ALLOWED_CALLBACK_HOSTS" "$WEB_PROPS"
fi
chown root:bigbluebutton "$WEB_PROPS" 2>/dev/null || true
chmod 640 "$WEB_PROPS"
ok "bbb-web.properties به‌روز شد"

# --- ۲) bbb-html5.yml (yq-go از پکیج bbb-yq-go) ---
log "۲) bbb-html5.yml: زبان و customStyleUrl"
test -s "$HTML5_CONFIG" || echo '{}' > "$HTML5_CONFIG"
if [[ -n "${BBB_DEFAULT_LOCALE:-}" ]]; then
  L="$BBB_DEFAULT_LOCALE" yq-go e -i '.public.app.defaultSettings.application.overrideLocale = strenv(L)' "$HTML5_CONFIG"
else
  yq-go e -i 'del(.public.app.defaultSettings.application.overrideLocale)' "$HTML5_CONFIG"
fi
L="${BBB_FALLBACK_LOCALE:-en}" yq-go e -i '.public.app.defaultSettings.application.fallbackLocale = strenv(L)' "$HTML5_CONFIG"
ASSETS_URL="${BBB_CUSTOM_ASSETS_URL:-/lms-assets}"
ASSETS_URL="/${ASSETS_URL#/}"
if [[ -f "$OVR/assets/custom.css" ]]; then
  U="https://${BBB_DOMAIN}${ASSETS_URL%/}/custom.css" yq-go e -i '.public.app.customStyleUrl = strenv(U)' "$HTML5_CONFIG"
else
  yq-go e -i 'del(.public.app.customStyleUrl)' "$HTML5_CONFIG"
fi
ok "bbb-html5.yml به‌روز شد"

# --- ۳) ضبط: فرمت‌ها، mp4، تعداد worker (T7) ---
log "۳) ضبط: فرمت‌ها ${BBB_RECORDING_FORMATS:-presentation,video}"
mkdir -p "$(dirname "$REC_OVERRIDE")"
if [[ ",${BBB_RECORDING_FORMATS:-presentation,video}," == *",video,"* ]]; then
  if ! dpkg -s bbb-playback-video >/dev/null 2>&1; then
    log "نصب bbb-playback-video"
    DEBIAN_FRONTEND=noninteractive apt-get install -y bbb-playback-video
  fi
  copy_if_changed "$OVR/recording.yml" "$REC_OVERRIDE" && ok "recording.yml (presentation + video) نصب شد" \
    || ok "recording.yml بدون تغییر"
else
  # فقط presentation: override را حذف کن تا مراحل پیش‌فرض bigbluebutton.yml اعمال شوند
  rm -f "$REC_OVERRIDE"
  ok "فقط presentation (override حذف شد)"
fi

# mp4 در presentation (برای iOS). فرمت video در 4.0 به‌صورت پیش‌فرض mp4 (m4v) می‌سازد
# (record-and-playback/video/scripts/video.yml)، پس video.yml تغییر نمی‌کند.
PRES_YML="$SCRIPTS_DIR/presentation.yml"
if [[ -f "$PRES_YML" ]]; then
  if [[ "${BBB_VIDEO_MP4:-true}" == true ]]; then
    sed -i -E 's/^#[[:space:]]*-[[:space:]]*mp4[[:space:]]*$/- mp4/' "$PRES_YML"
    grep -qE '^-[[:space:]]*mp4' "$PRES_YML" && ok "mp4 در presentation.yml فعال است" \
      || warn "خط mp4 در $PRES_YML پیدا نشد؛ ساختار فایل عوض شده؟"
  else
    sed -i -E 's/^-[[:space:]]*mp4[[:space:]]*$/# - mp4/' "$PRES_YML"
  fi
fi

# تعداد worker. هشدار مستند (customize.md، issue #12503): اگر defaultKeepEvents یا
# meetingKeepEvents روشن است، COUNT نباید بیشتر از ۱ شود (از دست رفتن events).
workers="${BBB_RAP_WORKERS:-1}"
[[ "$workers" =~ ^[1-9][0-9]*$ ]] || die "BBB_RAP_WORKERS باید عدد مثبت باشد (الان: $workers)"
keep_events="$(grep -hsE '^(defaultKeepEvents|meetingKeepEvents)=' "$WEB_PROPS" "$WEB_PROPS_DEFAULT" | grep -c '=true' || true)"
if ((workers > 1 && keep_events > 0)); then
  warn "defaultKeepEvents/meetingKeepEvents روشن است؛ BBB_RAP_WORKERS=$workers نادیده گرفته شد و ۱ ماند"
  workers=1
fi
DROPIN=/etc/systemd/system/bbb-rap-resque-worker.service.d/override.conf
TMP_DROPIN="$(mktemp)"
printf '[Service]\nEnvironment=COUNT=%s\n' "$workers" > "$TMP_DROPIN"
if copy_if_changed "$TMP_DROPIN" "$DROPIN"; then
  systemctl daemon-reload
  ok "تعداد worker ضبط = $workers"
else
  ok "تعداد worker ضبط بدون تغییر ($workers)"
fi
rm -f "$TMP_DROPIN"

# --- ۴) ترجمه‌ی فارسی کلاینت ---
if [[ -f "$OVR/fa_IR.json" ]]; then
  log "۴) کپی fa_IR.json"
  python3 -c 'import json,sys; json.load(open(sys.argv[1], encoding="utf-8"))' "$OVR/fa_IR.json" \
    || die "overrides/fa_IR.json معتبر نیست"
  copy_if_changed "$OVR/fa_IR.json" "$HTML5_DIR/locales/fa_IR.json" && ok "fa_IR.json جایگزین شد" \
    || ok "fa_IR.json بدون تغییر"
else
  log "۴) overrides/fa_IR.json نیست — رد شد"
fi

# --- ۵) فونت‌ها برای LibreOffice (T4) ---
fonts_changed=false
shopt -s nullglob
ttfs=("$OVR"/fonts/*.ttf)
if ((${#ttfs[@]})); then
  log "۵) نصب ${#ttfs[@]} فونت در ${BBB_FONTS_DIR:-/usr/share/fonts/truetype/lms-fa}"
  for f in "${ttfs[@]}" "$OVR"/fonts/LICENSE*; do
    copy_if_changed "$f" "${BBB_FONTS_DIR:-/usr/share/fonts/truetype/lms-fa}/$(basename "$f")" && fonts_changed=true
  done
fi
if [[ -f "$OVR/fonts/99-lms-fa.conf" ]]; then
  copy_if_changed "$OVR/fonts/99-lms-fa.conf" /etc/fonts/conf.d/99-lms-fa.conf && fonts_changed=true
fi
if $fonts_changed; then
  fc-cache -f >/dev/null
  ok "fc-cache به‌روز شد"
elif ((${#ttfs[@]})) || [[ -f "$OVR/fonts/99-lms-fa.conf" ]]; then
  ok "فونت‌ها بدون تغییر"
else
  log "۵) فونتی در overrides/fonts نیست — رد شد"
fi

# --- ۶) assetهای self-host (custom.css + woff2؛ T5) ---
if [[ -f "$OVR/assets/custom.css" ]]; then
  dest="$ASSETS_ROOT${ASSETS_URL%/}"
  log "۶) کپی assetها به $dest"
  mkdir -p "$dest"
  rsync -a --delete --exclude '.gitkeep' "$OVR/assets/" "$dest/"
  chmod -R a+rX "$dest"
  ok "assetها در https://${BBB_DOMAIN}${ASSETS_URL%/}/ سرو می‌شوند"
else
  log "۶) overrides/assets/custom.css نیست — رد شد"
fi
shopt -u nullglob

# --- ۷) نگهداری raw (published هرگز پاک نمی‌شود) ---
# cron.daily/bigbluebutton فقط raw ضبط‌هایی را پاک می‌کند که در همه‌ی فرمت‌ها published شده‌اند.
days="${BBB_RAW_RETENTION_DAYS:-14}"
[[ "$days" =~ ^[0-9]+$ ]] || die "BBB_RAW_RETENTION_DAYS باید عدد باشد (الان: $days)"
log "۷) پاک‌سازی raw بعد از $days روز ($CRON_CONFIG)"
set_prop published_days "$days" "$CRON_CONFIG"
ok "published_days=$days"

ok "apply-config.sh تمام شد"
