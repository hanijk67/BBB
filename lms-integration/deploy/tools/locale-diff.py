#!/usr/bin/env python3
"""مقایسه‌ی کلیدهای ترجمه‌ی کلاینت html5 (en.json در برابر fa_IR.json) — فاز ۳.

فقط stdlib؛ اجرا با:  python -I tools/locale-diff.py [--en PATH] [--fa PATH] [options]

پیش‌فرض‌ها:
  --en  سورس bigbluebutton: bigbluebutton-html5/public/locales/en.json
  --fa  lms-integration/deploy/overrides/fa_IR.json اگر هست، وگرنه fa_IR.json سورس

خروجی در tools/out/:
  missing_fa.json   کلیدهای ترجمه‌نشده → متن انگلیسی (به ترتیب en.json)
  obsolete_fa.txt   کلیدهایی که در fa هست و در en نیست
و خلاصه‌ی تعداد به تفکیک پیشوند (app.chat، app.userList، ...) روی stdout.

گزینه‌ها:
  --check               اگر کلیدی کم است exit 1
  --check-placeholders  placeholderها ({0}، {name}) و تگ‌های HTML ترجمه با en یکی باشند؛ وگرنه exit 1
  --export-new PATH     کلیدهایی از --fa که در fa_IR.json سورس نیستند یا مقدارشان فرق دارد
                        (ترجمه‌های ما، برای Transifex) به ترتیب en.json
"""

import argparse
import collections
import json
import re
import sys
from pathlib import Path

TOOLS_DIR = Path(__file__).resolve().parent
DEPLOY_DIR = TOOLS_DIR.parent
BBB_ROOT = DEPLOY_DIR.parent.parent
LOCALES_DIR = BBB_ROOT / "bigbluebutton-html5" / "public" / "locales"
OUT_DIR = TOOLS_DIR / "out"

PLACEHOLDER_RE = re.compile(r"\{[^{}]*\}")
TAG_RE = re.compile(r"</?\s*([A-Za-z][\w-]*)[^>]*>")


def load(path: Path) -> dict:
    raw = path.read_bytes()
    if raw.startswith(b"\xef\xbb\xbf"):
        sys.exit(f"خطا: {path} دارای BOM است (باید UTF-8 بدون BOM باشد)")
    try:
        data = json.loads(raw.decode("utf-8"), object_pairs_hook=collections.OrderedDict)
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        sys.exit(f"خطا: {path} JSON/UTF-8 معتبر نیست: {exc}")
    if not isinstance(data, dict):
        sys.exit(f"خطا: {path} باید یک object باشد")
    return data


def prefix(key: str) -> str:
    parts = key.split(".")
    return ".".join(parts[:2]) if len(parts) > 1 else parts[0]


def tokens(text: str) -> collections.Counter:
    found = PLACEHOLDER_RE.findall(text)
    found += [f"<{m.lower()}>" for m in TAG_RE.findall(text)]
    return collections.Counter(found)


def write_json(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, ensure_ascii=False, indent=4)
        f.write("\n")


def main() -> int:
    # کنسول ویندوز (cp1252) فارسی را چاپ نمی‌کند؛ با -I متغیر PYTHONIOENCODING هم نادیده گرفته می‌شود
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            stream.reconfigure(encoding="utf-8")
    ap =argparse.ArgumentParser(description="diff کلیدهای en.json و fa_IR.json")
    ap.add_argument("--en", type=Path, default=LOCALES_DIR / "en.json")
    default_fa = DEPLOY_DIR / "overrides" / "fa_IR.json"
    ap.add_argument("--fa", type=Path, default=default_fa if default_fa.exists() else LOCALES_DIR / "fa_IR.json")
    ap.add_argument("--out", type=Path, default=OUT_DIR)
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--check-placeholders", action="store_true")
    ap.add_argument("--export-new", type=Path)
    args = ap.parse_args()

    en = load(args.en)
    fa = load(args.fa)
    missing = collections.OrderedDict((k, v) for k, v in en.items() if k not in fa)
    obsolete = [k for k in fa if k not in en]

    write_json(args.out / "missing_fa.json", missing)
    (args.out / "obsolete_fa.txt").write_text("".join(k + "\n" for k in obsolete), encoding="utf-8", newline="\n")

    print(f"en: {args.en}  ({len(en)} کلید)")
    print(f"fa: {args.fa}  ({len(fa)} کلید)")
    print(f"ترجمه‌نشده: {len(missing)}   منسوخ: {len(obsolete)}")
    if missing:
        print("\nترجمه‌نشده به تفکیک پیشوند:")
        for p, n in collections.Counter(prefix(k) for k in missing).most_common():
            print(f"  {n:4d}  {p}")
    if obsolete:
        print("\nمنسوخ به تفکیک پیشوند:")
        for p, n in collections.Counter(prefix(k) for k in obsolete).most_common():
            print(f"  {n:4d}  {p}")
    print(f"\nخروجی: {args.out / 'missing_fa.json'}، {args.out / 'obsolete_fa.txt'}")

    status = 0
    if args.check_placeholders:
        bad = []
        for k, v in fa.items():
            if k in en and isinstance(v, str) and tokens(v) != tokens(en[k]):
                bad.append(k)
        if bad:
            print(f"\nFAIL placeholder/تگ ناهماهنگ در {len(bad)} کلید:")
            for k in bad:
                print(f"  {k}\n    en: {sorted(tokens(en[k]).elements())}\n    fa: {sorted(tokens(fa[k]).elements())}")
            status = 1
        else:
            print("\nPASS placeholderها و تگ‌ها با en یکی هستند")

    if args.check:
        if missing:
            print(f"FAIL {len(missing)} کلید ترجمه نشده است")
            status = 1
        else:
            print("PASS هیچ کلید en جا نیفتاده است")

    if args.export_new:
        source_fa = load(LOCALES_DIR / "fa_IR.json")
        new = collections.OrderedDict(
            (k, fa[k]) for k in en if k in fa and source_fa.get(k) != fa[k]
        )
        write_json(args.export_new, new)
        print(f"\n{len(new)} ترجمه‌ی جدید/تغییرکرده → {args.export_new}")

    return status


if __name__ == "__main__":
    sys.exit(main())
