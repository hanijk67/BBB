#!/usr/bin/env bash
# بکاپ روزانه‌ی ضبط‌های منتشرشده (و raw اختیاری) با rsync — فاز ۷.
# روی سرور BBB:  sudo tools/backup.sh [path/to/.env]
# پیش‌فرض .env: /etc/bigbluebutton/lms/.env (کپی install.sh).
#
# نمونه‌ی cron (هر شب ۰۲:۳۰؛ خروجی در syslog با tag bbb-backup):
#   30 2 * * * root /etc/bigbluebutton/lms/tools/backup.sh >/dev/null 2>&1
#
# کد خروج: 0 موفق، 1 خطای تنظیمات، 2 قفل (اجرای قبلی هنوز تمام نشده)، دیگر = کد rsync.
set -euo pipefail

TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="$TOOLS_DIR/../lib/env.sh"
[[ -f "$LIB" ]] || LIB=/etc/bigbluebutton/lms/lib/env.sh
# shellcheck source=../lib/env.sh
. "$LIB"

ENV_FILE="${1:-}"
if [[ -z "$ENV_FILE" && -f /etc/bigbluebutton/lms/.env ]]; then ENV_FILE=/etc/bigbluebutton/lms/.env; fi
load_env "$ENV_FILE"
require_vars BBB_BACKUP_DEST

DATA=/var/bigbluebutton
LOCK=/run/lms-bbb-backup.lock
LOG_TAG=bbb-backup
SSH_OPTS="${BBB_BACKUP_SSH_OPTS:--o BatchMode=yes -o ConnectTimeout=20}"

say() { log "$*"; logger -t "$LOG_TAG" -- "$*" 2>/dev/null || true; }

exec 9>"$LOCK"
if ! flock -n 9; then
  warn "بکاپ قبلی هنوز در حال اجراست"
  logger -t "$LOG_TAG" "skipped: previous run still active" 2>/dev/null || true
  exit 2
fi

dest="${BBB_BACKUP_DEST%/}"
sources=("$DATA/published")
[[ -d "$DATA/unpublished" ]] && sources+=("$DATA/unpublished")
if [[ "${BBB_BACKUP_INCLUDE_RAW:-false}" == true ]]; then
  sources+=("$DATA/recording/raw")
fi

rc=0
start=$(date +%s)
for src in "${sources[@]}"; do
  [[ -d "$src" ]] || { warn "مسیر $src وجود ندارد — رد شد"; continue; }
  rel="${src#"$DATA"/}"
  say "rsync $src → $dest/$rel"
  # --delete نمی‌زنیم: ضبطی که روی BBB پاک شد، در بکاپ می‌ماند
  rsync -a --partial --info=stats1 -e "ssh $SSH_OPTS" "$src"/ "$dest/$rel"/ || {
    rc=$?
    say "خطا: rsync $src با کد $rc"
  }
done

took=$(( $(date +%s) - start ))
if ((rc == 0)); then
  say "بکاپ موفق (${took}s)"
  ok "بکاپ موفق (${took}s)"
else
  say "بکاپ ناموفق (کد $rc، ${took}s)"
fi
exit "$rc"
