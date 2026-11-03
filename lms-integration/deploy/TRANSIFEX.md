# ارسال ترجمه‌ی فارسی به Transifex خود BigBlueButton (T2)

> هدف: ترجمه‌ای که ما در `overrides/fa_IR.json` کامل کردیم وارد خود BBB شود تا بعد از چند ریلیز
> overlay ما لازم نباشد. این کار **دستی و با حساب خود شما** است؛ Claude حساب نمی‌سازد و چیزی
> ارسال نمی‌کند.

## چرا مهم است

- طبق `docs/docs/development/localization.md`: Transifex فقط وقتی برای یک زبان PR خودکار به گیت‌هاب
  BBB می‌فرستد که آن زبان **۱۰۰٪ کامل** باشد (یا رشته‌ای در زبانی که ۱۰۰٪ است تغییر کند).
  فارسی الان ۳۴۵ رشته کم دارد، پس بدون ارسال ما ترجمه‌ها هرگز وارد ریلیز نمی‌شوند.
- `transifex.yml` ریشه‌ی سورس: منبع `bigbluebutton-html5/public/locales/en.json`، فرمت
  `KEYVALUEJSON`، فایل هر زبان `bigbluebutton-html5/public/locales/<lang>.json` (برای ما `fa_IR`).

## فایل‌های آماده

| فایل | محتوا | کاربرد |
|---|---|---|
| `tools/out/transifex-fa-new.json` | فقط ۳۵۶ کلیدی که ما اضافه/اصلاح کردیم (۳۴۵ جدید + ۱۱ اصلاح placeholder) | مرور و review، کپی دستی در ویرایشگر |
| `overrides/fa_IR.json` | فایل کامل (۱۸۴۲ کلید، دقیقاً کلیدهای en.json، بدون کلید منسوخ) | آپلود یک‌جا (پیشنهادی) |

`tools/out/` در git نیست؛ اگر پاک شده، دوباره بسازید:

```bash
python -I tools/locale-diff.py --check --check-placeholders --export-new tools/out/transifex-fa-new.json
```

## قدم‌به‌قدم

1. **ساخت حساب:** در https://www.transifex.com ثبت‌نام کنید (ایمیل کاری، نام واقعی؛ تیم‌ها
   درخواست حساب‌های بی‌نام را دیرتر تأیید می‌کنند).
2. **پیدا کردن پروژه:** https://app.transifex.com/bigbluebutton/ → پروژه‌ی BigBlueButton.
   resource مربوط به کلاینت html5 برای **همان برنچ 4.0** را پیدا کنید (منبعش `en.json` است). اگر
   چند resource برای برنچ‌های مختلف هست، فقط روی resource نسخه‌ی 4.0 کار کنید.
3. **درخواست عضویت در تیم فارسی:** در صفحه‌ی پروژه زبان **Persian (Iran) / fa_IR** را باز کنید و
   «Join team» / درخواست عضویت به‌عنوان translator بدهید. اگر زبان نبود، از منوی Transifex
   درخواست اضافه شدن زبان بدهید. منتظر تأیید coordinator تیم بمانید (ممکن است چند روز طول بکشد؛
   می‌توانید در بخش پیام‌های تیم کوتاه توضیح دهید که ۳۴۵ رشته‌ی ۴.۰ را ترجمه کرده‌اید).
4. **وارد کردن ترجمه‌ها** — یکی از دو روش:
   - **آپلود فایل (پیشنهادی):** در صفحه‌ی زبان fa_IR آن resource، گزینه‌ی آپلود فایل ترجمه را
     بزنید و `overrides/fa_IR.json` را بدهید. چون همه‌ی کلیدها با en.json یکی است، فرمت
     KEYVALUEJSON مستقیم قبول می‌شود. قبل از آپلود، از ترجمه‌ی فعلی همان‌جا یک نسخه دانلود کنید
     (بکاپ).
   - **ویرایشگر وب:** فیلتر «Untranslated» را بزنید و از روی `tools/out/transifex-fa-new.json`
     کلید به کلید paste کنید (کند، ولی هر رشته جدا review می‌شود).
5. **۱۱ رشته‌ی اصلاحی** (در فایل جدید هستند ولی در Transifex «ترجمه‌شده» حساب می‌شوند): این‌ها
   placeholder اشتباه داشتند، مثلاً `app.guest-policy.feedbackMessage` بدون `{policy}`. در فیلتر
   «Translated» جستجو و اصلاح کنید:
   `app.chat.titlePrivate`، `app.meeting.endedByNoModeratorMessagePlural`،
   `app.presentationUploder.uploading`، `app.statusNotifier.lowerHandDescOneUser`،
   `app.statusNotifier.raisedHandsTitle`، `app.userList.guest.allowAllAuthenticated`،
   `app.userList.guest.allowAllGuests`، `app.userList.guest.allowEveryone`،
   `app.userList.guest.denyEveryone`، `app.shortcut-help.fingerTap`،
   `app.guest-policy.feedbackMessage`.
6. **بررسی:** درصد fa_IR در آن resource باید **۱۰۰٪** شود. اگر نشد، کلیدهای جدیدی بعد از تاریخ
   ما به en.json اضافه شده‌اند → `locale-diff.py` را روی سورس به‌روز اجرا کنید، ترجمه کنید، هم
   overlay و هم Transifex.
7. **پیگیری:** بعد از ۱۰۰٪ شدن، Transifex خودش PR به `bigbluebutton/bigbluebutton` می‌فرستد
   (نمونه: PR شماره‌ی 17799 همان مستند). ترجمه در **ریلیز بعدی** همان برنچ وارد پکیج می‌شود.
   بعد از آن ریلیز، `locale-diff.py --fa <fa_IR.json نسخه‌ی جدید>` را اجرا کنید؛ اگر صفر کم
   داشت، کپی `fa_IR.json` در `apply-config.sh` دیگر لازم نیست (ولی ضرری هم ندارد).

## نکات review

- واژه‌ها طبق `tools/glossary-fa.md` (همان معادل‌های فعلی fa_IR.json: «مدیر»، «ارائه‌دهنده»،
  «گپ»، «اتاق جانبی»، «هم‌رسانی»، «تخته‌سفید»، «آزمونک» برای Quiz).
- placeholderها (`{count}`، `{userName}`، ...) دست نخورند؛ Transifex هم هشدار می‌دهد.
- نیم‌فاصله و «ی/ک» فارسی؛ Transifex گاهی هنگام paste نیم‌فاصله را حذف می‌کند — چند نمونه را
  بعد از ذخیره چک کنید.
- اگر reviewer تیم فارسی معادل دیگری را ترجیح داد، همان را در `overrides/fa_IR.json` و
  `glossary-fa.md` هم اعمال کنید تا دو نسخه یکی بمانند.
- کلیدهایی که ترجمه‌شان قطعی نیست (در تاریخچه‌ی تسک 06/07 لیست شده) را در Transifex با کامنت
  «needs review» علامت بزنید.

## وضعیت

- [ ] حساب ساخته شد
- [ ] عضویت در تیم fa_IR تأیید شد
- [ ] ترجمه‌ها وارد شد و fa_IR = ۱۰۰٪
- [ ] PR خودکار Transifex در گیت‌هاب BBB دیده شد
