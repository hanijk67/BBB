#!/usr/bin/env bash
# اندازه‌گیری پردازش ضبط یک جلسه (T7، فاز ۷) — زمان و حجم هر فرمت.
# استفاده (روی سرور BBB، بعد از اینکه همه‌ی فرمت‌ها published شدند):
#   sudo tools/measure-recording.sh <recordID>
# recordID را از `bbb-record --list` یا ستون record_id در جدول meeting_recordings بگیرید.
# خروجی یک خط CSV برای هر فرمت: recordID,format,archived_at,published_at,processing_min,size_mb
set -euo pipefail

id="${1:-}"
[[ -n "$id" ]] || { echo "استفاده: $0 <recordID>" >&2; exit 1; }
status=/var/bigbluebutton/recording/status
[[ -f "$status/archived/$id.done" ]] || { echo "خطا: $id هنوز archive نشده" >&2; exit 1; }

archived="$(stat -c %Y "$status/archived/$id.done")"
echo "recordID,format,archived_at,published_at,processing_min,size_mb"
found=0
for done in "$status"/published/"$id"-*.done; do
  [[ -e "$done" ]] || continue
  found=1
  fmt="$(basename "$done" .done)"; fmt="${fmt#"$id"-}"
  published="$(stat -c %Y "$done")"
  minutes=$(( (published - archived + 59) / 60 ))
  size_mb="$(du -sm "/var/bigbluebutton/published/$fmt/$id" 2>/dev/null | awk '{print $1}')"
  echo "$id,$fmt,$(date -d "@$archived" '+%F %T'),$(date -d "@$published" '+%F %T'),$minutes,${size_mb:-?}"
done
((found)) || { echo "هیچ فرمتی هنوز published نشده" >&2; exit 1; }

raw_mb="$(du -sm "/var/bigbluebutton/recording/raw/$id" 2>/dev/null | awk '{print $1}')"
echo "# raw: ${raw_mb:-?} MB — مدت جلسه را از getRecordings (startTime/endTime) بردارید" >&2
