# پرامپت‌های اجرای تسک‌های BBB (به ترتیب)

> منبع: [`lms-integration/BBB_INTEGRATION_PLAN.md`](BBB_INTEGRATION_PLAN.md). هر تسک = یک پرامپت مستقل.
> پرامپت‌ها را **به ترتیب**، هر کدام در یک چت/سشن جدید Claude Code (working dir:
> `F:\omid\Lms_Micro_Git\bigbluebutton`، دایرکتوری اضافه: `F:\omid\Lms_Micro_Git\LMS_MICRO`)
> کپی کنید. هر تسک فقط بعد از تمام شدن تسک قبلی شروع شود.
>
> **دو پروژه‌ی جدا:**
> - پروژه‌ی BBB = `F:\omid\Lms_Micro_Git\bigbluebutton` — این فایل‌ها و همه‌ی مسیرهای
>   `lms-integration/...` (اسکریپت‌های نصب، overrides، ترجمه، فونت) در این پروژه‌اند.
> - پروژه‌ی LMS = `F:\omid\Lms_Micro_Git\LMS_MICRO` — همه‌ی مسیرهای کد LMS
>   (`virtual-classroom-service/`، `config-service/`، `gateway-service/`، `notification-service/`،
>   `course-service/`، `frontend/`، `docker-compose*.yml`، `docs/DEPLOYMENT.md`،
>   `docs/ARCHITECTURE.md`) نسبت به این مسیرند. تسک‌های 11 تا 19 (و بخش مستندات تسک 22) در
>   این پروژه تغییر می‌دهند.
>
> برچسب‌ها: **[کد]** = Claude خودش انجام می‌دهد · **[سرور]** = اجرا روی سرور توسط شما، Claude
> اسکریپت/راهنما می‌دهد و خروجی را بررسی می‌کند · **[تصمیم]** = نیاز به جواب شما.

---

## قوانین مشترک (در همه‌ی پرامپت‌ها تکرار شده — حذف نکنید)

هر پرامپت به این بلوک ارجاع می‌دهد و Claude باید آن را رعایت کند:

```
قوانین مشترک:
1. اول lms-integration/BBB_INTEGRATION_PLAN.md و F:\omid\Lms_Micro_Git\LMS_MICRO\CLAUDE.md را کامل بخوان. قانون Liquibase در آن
   را رعایت کن: هیچ changeset اجراشده‌ای ادیت نشود؛ فقط changeset جدید در انتهای فایل.
2. فقط کارهای همین تسک را انجام بده. اگر چیزی از تسک‌های قبلی ناقص است، گزارش کن، خودسرانه
   جلو نرو.
3. بعد از اتمام، در lms-integration/BBB_INTEGRATION_PLAN.md چک‌باکس‌های انجام‌شده‌ی همین تسک را [x] کن.
4. تاریخچه: یک فایل در مسیر "F:\project\clude doc\bbb" بساز با نام
   YYYY-MM-DD-bbb-<شماره تسک>-<slug>.md (تاریخ امروز) با این بخش‌ها:
   # تاریخچه — <عنوان تسک> (<تاریخ>)
   ## درخواست      (شماره و عنوان تسک + خلاصه‌ی پرامپت)
   ## بررسی        (چه چیزهایی دیدی/تأیید کردی، با مسیر فایل‌ها)
   ## تغییرات      (فایل به فایل، چه چیزی و چرا)
   ## وضعیت        (چه چیزی تست/اجرا شد و نتیجه؛ چه چیزی تست نشد)
   ## نکته / ریسک  (کارهای باقی‌مانده، تصمیم‌های لازم، ریسک‌ها)
   سپس یک خط به "F:\project\clude doc\bbb\00-INDEX.md" اضافه کن (اگر نیست بساز):
   - <تاریخ> — تسک <شماره> — <عنوان> — <نام فایل تاریخچه> — <انجام شد | ناقص: دلیل>
5. پروژه‌ی LMS: روی برنچ main کار کن، برنچ جدید نساز. پروژه‌ی BBB: کلون upstream است
   (برنچ v4.0.x-develop)؛ فقط داخل lms-integration/ فایل بساز و به سورس upstream دست نزن.
   commit و push در هر دو پروژه فقط اگر من خواستم.
6. secret واقعی (رمز، توکن، shared secret) در هیچ فایل commit‌شدنی یا فایل تاریخچه ننویس.
```

---

## تسک 00 — تصمیم‌های باز فاز ۰ [تصمیم]

```
تسک 00 از lms-integration/BBB_TASK_PROMPTS.md: تصمیم‌های باز فاز ۰ در lms-integration/BBB_INTEGRATION_PLAN.md.

- D1: صفحه‌ی https://github.com/bigbluebutton/bigbluebutton/releases را بررسی کن و بگو
  آخرین نسخه‌ی stable 4.0.x و 3.0.x چیست. پیشنهادت را بده و منتظر جواب من بمان.
- D4: از من دامنه‌ی BBB (پیشنهاد class.glmp.ir) و دامنه‌ی TURN (پیشنهاد turn.glmp.ir) را بپرس.
- D5: از من حداکثر کلاس هم‌زمان، حداکثر نفر در کلاس و تعداد وبکم هم‌زمان را بپرس؛ بر اساس
  مستند install.md در سورس bigbluebutton و جواب من، سایز CPU/RAM/دیسک/پهنای‌باند سرور BBB و
  سرور TURN را پیشنهاد بده (تخمین را صریحاً تخمین بنام).
- جواب‌ها را در فاز ۰ همان فایل ثبت و D1/D4/D5 را [x] کن. اگر نسخه 3.0 انتخاب شد، تمام
  ارجاع‌های noble-400 / Ubuntu 24.04 در plan را مطابق README برنچ مربوط bbb-install اصلاح کن.

قبل از شروع، بخش «قوانین مشترک» در lms-integration/BBB_TASK_PROMPTS.md را بخوان و کامل رعایت کن
(به‌خصوص ثبت تاریخچه در "F:\project\clude doc\bbb" و به‌روزرسانی 00-INDEX.md).
```

## تسک 01 — اسکلت `lms-integration/deploy` و `.env.example` [کد]

```
تسک 01 از lms-integration/BBB_TASK_PROMPTS.md: ساخت پوشه‌ی lms-integration/deploy طبق فاز ۲ در
lms-integration/BBB_INTEGRATION_PLAN.md.

- lms-integration/deploy/.env.example با همه‌ی متغیرهای لیست‌شده در فاز ۲ (و مقادیر دامنه از تسک 00)،
  هر متغیر با کامنت فارسی کوتاه. مقدار secretها خالی.
- lms-integration/deploy/.gitignore که .env واقعی را ignore کند.
- lms-integration/deploy/README.md: ساختار پوشه، ترتیب اجرای اسکریپت‌ها (TURN → BBB → apply-config)،
  پیش‌نیازهای فاز ۱ به صورت چک‌لیست. فقط اسکلت؛ جزئیات runbook در تسک 22.
- پوشه‌های خالی overrides/assets/fonts، overrides/fonts، tools با .gitkeep.
- یک اسکریپت مشترک lms-integration/deploy/lib/env.sh که .env را load و متغیرهای اجباری را validate کند
  (اگر خالی بود با پیام فارسی خطا بدهد و exit 1).
- اسکریپت‌ها bash با set -euo pipefail و LF line ending (gitattributes برای *.sh در صورت نیاز).
- shellcheck اگر در دسترس است اجرا کن؛ در غیر این صورت bash -n.

قبل از شروع، بخش «قوانین مشترک» در lms-integration/BBB_TASK_PROMPTS.md را بخوان و کامل رعایت کن
(به‌خصوص ثبت تاریخچه در "F:\project\clude doc\bbb" و به‌روزرسانی 00-INDEX.md).
```

## تسک 02 — اسکریپت سرور TURN [کد]

```
تسک 02 از lms-integration/BBB_TASK_PROMPTS.md: بخش «۱-ب — سرور TURN جدا (T3)» در
lms-integration/BBB_INTEGRATION_PLAN.md.

- مستند F:\omid\Lms_Micro_Git\bigbluebutton\docs\docs\administration\turn-server.md و README
  برنچ v4.0.x-release مخزن bbb-install را بخوان.
- lms-integration/deploy/install-turn.sh: از lib/env.sh استفاده کند؛ چک Ubuntu 24.04، چک DNS
  BBB_TURN_HOST → IP همین سرور، چک آزاد بودن 443؛ تنظیم ufw برای 22، 3478 tcp/udp،
  443 tcp/udp، 32769-65535 udp؛ دانلود bbb-install.sh از برنچ صحیح و اجرای
  -c "$BBB_TURN_HOST:$BBB_TURN_SECRET" -e "$BBB_LETSENCRYPT_EMAIL" بدون -v.
  validate کند طول BBB_TURN_SECRET بین ۸ تا ۱۶ کاراکتر است.
- lms-integration/deploy/tools/check-turn.sh: تست پورت‌ها از بیرون و راهنمای تست relay (about:webrtc).
- بخش TURN در lms-integration/deploy/README.md.
- اسکریپت را اجرا نکن (سرور در دسترس نیست)؛ فقط bash -n / shellcheck.

قبل از شروع، بخش «قوانین مشترک» در lms-integration/BBB_TASK_PROMPTS.md را بخوان و کامل رعایت کن
(به‌خصوص ثبت تاریخچه در "F:\project\clude doc\bbb" و به‌روزرسانی 00-INDEX.md).
```

## تسک 03 — اسکریپت نصب BBB و مسیر ضبط از `.env` [کد]

```
تسک 03 از lms-integration/BBB_TASK_PROMPTS.md: install.sh در فاز ۲ و چک‌های فاز ۱ در
lms-integration/BBB_INTEGRATION_PLAN.md.

- lms-integration/deploy/tools/preflight.sh: چک‌های فاز ۱ (Ubuntu 24.04 / کرنل 6.x، nproc، free -h،
  IPv6 ::1، DNS BBB_DOMAIN، اشغال نبودن 80/443، دسترسی به ubuntu.bigbluebutton.org و
  Docker Hub و Let's Encrypt). خروجی خوانا PASS/FAIL به فارسی.
- lms-integration/deploy/install.sh:
  1) preflight.sh
  2) DOCKER_REGISTRY_MIRROR اگر ست است → /etc/docker/daemon.json (merge، نه overwrite کور)
  3) دانلود bbb-install.sh و اجرا با -v "$BBB_VERSION" -s "$BBB_DOMAIN"
     -e "$BBB_LETSENCRYPT_EMAIL" -c "$BBB_TURN_HOST:$BBB_TURN_SECRET" (بدون -g)
  4) انتقال /var/bigbluebutton به BBB_RECORDINGS_DIR با bind mount در /etc/fstab دقیقاً طبق
     plan؛ idempotent (اگر قبلاً mount شده دوباره کاری نکند، fstab تکراری نشود)؛ قبل از mv
     بررسی فضای دیسک مقصد.
  5) نصب lms-integration/deploy/apply-config.sh در /etc/bigbluebutton/bbb-conf/apply-config.sh
     (خود فایل در تسک 04 ساخته می‌شود؛ اگر هنوز نیست خطای واضح بدهد)
  6) bbb-conf --restart و bbb-conf --check
- هر مرحله قابل اجرای مجدد (idempotent) باشد.
- اجرا نکن؛ فقط bash -n / shellcheck.

قبل از شروع، بخش «قوانین مشترک» در lms-integration/BBB_TASK_PROMPTS.md را بخوان و کامل رعایت کن
(به‌خصوص ثبت تاریخچه در "F:\project\clude doc\bbb" و به‌روزرسانی 00-INDEX.md).
```

## تسک 04 — `apply-config.sh` و overrides ضبط/config [کد]

```
تسک 04 از lms-integration/BBB_TASK_PROMPTS.md: apply-config.sh در فاز ۲ (T2، T7) در
lms-integration/BBB_INTEGRATION_PLAN.md.

- قبل از نوشتن، در سورس bigbluebutton این‌ها را تأیید کن و مسیرها را از سورس بیاور، نه از حدس:
  /etc/bigbluebutton/bbb-web.properties (override)، /etc/bigbluebutton/bbb-html5.yml،
  /etc/bigbluebutton/recording/recording.yml، video.yml و presentation.yml (فعال‌کردن mp4)،
  مسیر locale کلاینت html5 (build/packages-template/bbb-html5/build.sh)،
  root پیش‌فرض nginx برای assetها، نحوه‌ی تنظیم COUNT برای bbb-rap-resque-worker.
- lms-integration/deploy/overrides/recording.yml با دو فرمت presentation و video.
- lms-integration/deploy/apply-config.sh (خودکفا: .env را از مسیر ثابت مثل /etc/bigbluebutton/lms/.env
  بخواند؛ install.sh هم .env را آنجا کپی کند — install.sh را به‌روز کن):
  - set_prop برای bbb-web.properties: securitySalt=BBB_SHARED_SECRET، defaultGuestPolicy،
    disableRecordingDefault=false، autoStartRecording=false، allowStartStopRecording=true،
    notifyRecordingIsOn=true، fetchUrlAllowedLocalHosts (اگر BBB_ALLOWED_CALLBACK_HOSTS ست است).
  - yq برای bbb-html5.yml: overrideLocale (اگر BBB_DEFAULT_LOCALE خالی نیست)، fallbackLocale،
    customStyleUrl.
  - recording.yml + apt install bbb-playback-video (اگر نصب نیست) + mp4 + COUNT از
    BBB_RAP_WORKERS (با هشدار مستند درباره‌ی KeepEvents).
  - کپی fa_IR.json، فونت‌ها، fontconfig و assetها **فقط اگر فایل‌ها در overrides وجود دارند**
    (تسک‌های 07 تا 09 پرشان می‌کنند) + fc-cache -f.
  - retention: پاک‌سازی raw قدیمی‌تر از BBB_RAW_RETENTION_DAYS (تنظیم cron موجود
    /etc/cron.daily/bigbluebutton؛ published هرگز پاک نشود).
  - همه idempotent؛ لاگ فارسی هر مرحله.
- اجرا نکن؛ bash -n / shellcheck.

قبل از شروع، بخش «قوانین مشترک» در lms-integration/BBB_TASK_PROMPTS.md را بخوان و کامل رعایت کن
(به‌خصوص ثبت تاریخچه در "F:\project\clude doc\bbb" و به‌روزرسانی 00-INDEX.md).
```

## تسک 05 — ابزار diff کلیدهای ترجمه [کد]

```
تسک 05 از lms-integration/BBB_TASK_PROMPTS.md: اسکریپت diff کلیدها در فاز ۳ در
lms-integration/BBB_INTEGRATION_PLAN.md.

- lms-integration/deploy/tools/locale-diff.py (Python 3، فقط stdlib، اجرا با python -I):
  ورودی: مسیر en.json و fa_IR.json (پیش‌فرض: سورس bigbluebutton و
  lms-integration/deploy/overrides/fa_IR.json اگر هست، وگرنه fa_IR.json سورس).
  خروجی: lms-integration/deploy/tools/out/missing_fa.json (کلید → متن انگلیسی، به ترتیب en.json)،
  obsolete_fa.txt، و خلاصه‌ی تعداد به تفکیک پیشوند (app.chat، app.userList، ...).
  گزینه‌ی --check: اگر کلیدی کم است exit 1 (برای استفاده در تسک 07).
  گزینه‌ی --check-placeholders: placeholderها ({0}، {name}، تگ‌ها) در ترجمه با en یکی باشند.
- lms-integration/deploy/tools/out/ به .gitignore.
- اجرا کن و اعداد را با plan مقایسه کن (انتظار: ۳۴۵ کم، ۷۹ منسوخ؛ اگر سورس آپدیت شده فرق
  کند، plan را به‌روز کن).
- lms-integration/deploy/tools/glossary-fa.md: اصطلاحات یکدست (moderator→مدیر جلسه، presenter→ارائه‌دهنده،
  viewer→شرکت‌کننده، breakout room→اتاق جانبی، ...) — اول از ترجمه‌های موجود fa_IR.json
  استخراج کن که الان چه معادلی استفاده شده و همان را مبنا بگذار.

قبل از شروع، بخش «قوانین مشترک» در lms-integration/BBB_TASK_PROMPTS.md را بخوان و کامل رعایت کن
(به‌خصوص ثبت تاریخچه در "F:\project\clude doc\bbb" و به‌روزرسانی 00-INDEX.md).
```

## تسک 06 — ترجمه‌ی کلیدهای اولویت ۱ [کد]

```
تسک 06 از lms-integration/BBB_TASK_PROMPTS.md: ترجمه‌ی اولویت ۱ فاز ۳ در lms-integration/BBB_INTEGRATION_PLAN.md.

- lms-integration/deploy/tools/locale-diff.py را اجرا کن.
- کلیدهای کم‌شده با پیشوند app.chat، app.userList، app.lock-viewers، app.recording،
  app.audio، app.actionsBar، app.guest، app.unmute، app.video، app.toast، app.notification،
  app.navBar، app.sidebarNavigation، app.sidebarContent، app.statusNotifier،
  app.talkingIndicator، app.error را به فارسی ترجمه کن.
- طبق lms-integration/deploy/tools/glossary-fa.md؛ placeholderها و تگ‌ها دست نخورند؛ نیم‌فاصله درست؛
  برای فهم context هر کلید، محل استفاده‌اش در bigbluebutton-html5/imports را grep کن.
- نتیجه: lms-integration/deploy/overrides/fa_IR.json = fa_IR.json سورس + ترجمه‌های جدید (کلیدهای منسوخ
  هنوز حذف نشوند). ترتیب کلیدها مثل en.json.
- locale-diff.py --check-placeholders باید پاس شود.
- در تاریخچه تعداد ترجمه‌شده به تفکیک پیشوند و کلیدهایی که ترجمه‌شان مطمئن نیست را بنویس.

قبل از شروع، بخش «قوانین مشترک» در lms-integration/BBB_TASK_PROMPTS.md را بخوان و کامل رعایت کن
(به‌خصوص ثبت تاریخچه در "F:\project\clude doc\bbb" و به‌روزرسانی 00-INDEX.md).
```

## تسک 07 — ترجمه‌ی باقی کلیدها و نهایی‌سازی `fa_IR.json` [کد]

```
تسک 07 از lms-integration/BBB_TASK_PROMPTS.md: ترجمه‌ی اولویت ۲ و merge نهایی فاز ۳ در
lms-integration/BBB_INTEGRATION_PLAN.md.

- همه‌ی کلیدهای کم‌شده‌ی باقی‌مانده (breakout، poll، timer، notes، learningDashboard،
  appsGallery، settings، submenu و بقیه) را ترجمه کن؛ قواعد تسک 06.
- کلیدهای منسوخ (در fa هست، در en نیست) را از lms-integration/deploy/overrides/fa_IR.json حذف کن.
- locale-diff.py --check و --check-placeholders هر دو پاس شوند؛ JSON معتبر و UTF-8 بدون BOM.
- فایل lms-integration/deploy/tools/out/transifex-fa-new.json: فقط کلیدهایی که ما ترجمه کردیم (برای تسک 10).

قبل از شروع، بخش «قوانین مشترک» در lms-integration/BBB_TASK_PROMPTS.md را بخوان و کامل رعایت کن
(به‌خصوص ثبت تاریخچه در "F:\project\clude doc\bbb" و به‌روزرسانی 00-INDEX.md).
```

## تسک 08 — فونت و CSS کلاینت، self-host + جهت متن چت [کد]

```
تسک 08 از lms-integration/BBB_TASK_PROMPTS.md: «فونت فارسی کلاینت، self-host (T5)» و «جهت متن چت» در
فاز ۳ lms-integration/BBB_INTEGRATION_PLAN.md.

- فونت Vazirmatn: نسخه‌ی ریلیز رسمی (github.com/rastikerdar/vazirmatn) را مشخص کن. دانلود فایل
  نیاز به اجازه‌ی من دارد: نام فایل، منبع و حجم را بگو و صبر کن. بعد از دانلود در پوشه‌ی جدا
  (فایل دانلودی untrusted است)، فقط woff2 های لازم (Regular، Medium، Bold) + LICENSE (OFL) را
  در lms-integration/deploy/overrides/assets/fonts/ بگذار.
- lms-integration/deploy/overrides/assets/custom.css: @font-face فقط با url نسبی (./fonts/...)، اعمال روی
  [dir="rtl"] و html[lang^="fa"]؛ هیچ URL خارجی.
- جهت متن پیام چت: selector دقیق متن پیام را در
  bigbluebutton-html5/imports/ui/components/chat/chat-graphql/chat-message-list پیدا کن
  (ترجیحاً data-test یا ساختار پایدار، نه کلاس هش‌شده‌ی styled-components) و
  unicode-bidi: plaintext; text-align: start; بده. اگر selector پایدار نیست، صریحاً در
  تاریخچه بنویس و گزینه‌ها را بده.
- apply-config.sh: کپی assets به مسیر nginx (از تسک 04) و customStyleUrl.
- grep روی lms-integration/deploy برای "http" در css تا مطمئن شوی هیچ آدرس خارجی نیست.

قبل از شروع، بخش «قوانین مشترک» در lms-integration/BBB_TASK_PROMPTS.md را بخوان و کامل رعایت کن
(به‌خصوص ثبت تاریخچه در "F:\project\clude doc\bbb" و به‌روزرسانی 00-INDEX.md).
```

## تسک 09 — فونت فارسی برای تبدیل اسلاید (LibreOffice) [کد]

```
تسک 09 از lms-integration/BBB_TASK_PROMPTS.md: «اسلاید فارسی (T4)» در فاز ۳
lms-integration/BBB_INTEGRATION_PLAN.md.

- در سورس bigbluebutton/bbb-libreoffice/assets/convert-local.sh تأیید کن که کانتینر
  bbb-soffice فونت‌های host (/usr/share/fonts، /etc/fonts، /var/cache/fontconfig) را mount
  می‌کند.
- فونت‌های ttf آزاد (Vazirmatn؛ اختیاری Sahel، Shabnam، Samim — همه OFL): مثل تسک 08، قبل از
  دانلود نام/منبع/حجم را بگو و اجازه بگیر. فقط ttf لازم + LICENSE در lms-integration/deploy/overrides/fonts/.
- lms-integration/deploy/overrides/fonts/99-lms-fa.conf (fontconfig): alias برای B Nazanin، B Titr،
  B Mitra، B Lotus، B Yekan، IRANSans، Tahoma → Vazirmatn. فونت غیرآزاد اضافه نکن.
- apply-config.sh: کپی ttf به BBB_FONTS_DIR، conf به /etc/fonts/conf.d/، fc-cache -f.
- lms-integration/deploy/tools/test-slides/README.md: روش تست (PPTX با B Nazanin، DOCX فارسی، PDF) و
  معیار پذیرش.

قبل از شروع، بخش «قوانین مشترک» در lms-integration/BBB_TASK_PROMPTS.md را بخوان و کامل رعایت کن
(به‌خصوص ثبت تاریخچه در "F:\project\clude doc\bbb" و به‌روزرسانی 00-INDEX.md).
```

## تسک 10 — بسته‌ی ارسال ترجمه به Transifex [کد + کار دستی شما]

```
تسک 10 از lms-integration/BBB_TASK_PROMPTS.md: «ارسال ترجمه به Transifex خود BBB (T2)» در فاز ۳
lms-integration/BBB_INTEGRATION_PLAN.md.

- bigbluebutton/docs/docs/development/localization.md و transifex.yml را بخوان.
- lms-integration/deploy/tools/out/transifex-fa-new.json (از تسک 07) را بررسی کن که کامل است.
- lms-integration/deploy/TRANSIFEX.md: راهنمای قدم‌به‌قدم فارسی برای من (ساخت حساب، درخواست عضویت در
  تیم فارسی پروژه، آپلود/وارد کردن ترجمه‌ها، نکات review). خودت در Transifex حساب نساز و
  چیزی ارسال نکن.
- در plan این چک‌باکس را [x] نکن تا من بگویم ارسال شد؛ در تاریخچه وضعیت «منتظر ارسال دستی».

قبل از شروع، بخش «قوانین مشترک» در lms-integration/BBB_TASK_PROMPTS.md را بخوان و کامل رعایت کن
(به‌خصوص ثبت تاریخچه در "F:\project\clude doc\bbb" و به‌روزرسانی 00-INDEX.md).
```

## تسک 11 — `MeetingProvider` و انتقال Adobe پشت آن (بدون تغییر رفتار) [کد]

```
تسک 11 از lms-integration/BBB_TASK_PROMPTS.md: «Provider abstraction (T6)» در فاز ۴
lms-integration/BBB_INTEGRATION_PLAN.md.

- virtual-classroom-service/virtual-classroom-service را کامل بخوان (client، config، service،
  model، dto، test).
- اینترفیس MeetingProvider طبق plan؛ AdobeConnectProvider که منطق فعلی AdobeConnectClient را
  بدون تغییر رفتار پیاده می‌کند؛ VirtualClassroomServiceImpl فقط به MeetingProvider وابسته.
- انتخاب با virtual-classroom.provider (پیش‌فرض BBB) و @ConditionalOnProperty؛ چون BbbProvider
  هنوز نیست (تسک 12)، فعلاً اگر BBB انتخاب شد سرویس با پیام واضح بالا بیاید یا یک
  NoOp/Stub موقت با لاگ هشدار — انتخاب و دلیلش را در تاریخچه بنویس.
- هیچ تغییری در Liquibase یا config-service در این تسک نده.
- mvn -f virtual-classroom-service/virtual-classroom-service/pom.xml test باید پاس شود (اگر
  ابتدا lms-common/parent install لازم است، انجام بده). تست‌های Adobe موجود بدون تغییر رفتار
  پاس شوند.

قبل از شروع، بخش «قوانین مشترک» در lms-integration/BBB_TASK_PROMPTS.md را بخوان و کامل رعایت کن
(به‌خصوص ثبت تاریخچه در "F:\project\clude doc\bbb" و به‌روزرسانی 00-INDEX.md).
```

## تسک 12 — `BbbProperties` و `BbbClient` [کد]

```
تسک 12 از lms-integration/BBB_TASK_PROMPTS.md: BbbProperties و BbbClient در فاز ۴
lms-integration/BBB_INTEGRATION_PLAN.md.

- پارامترها را از سورس bbb-common-web/src/main/java/org/bigbluebutton/api/ApiParams.java و
  docs/docs/development/api.md در سورس bigbluebutton تأیید کن.
- BbbProperties (@ConfigurationProperties("bbb")) با همه‌ی فیلدهای plan، شامل
  record-video-default و notify-recording-is-on / notify-recording-append.
- BbbClient: checksum = sha256(callName + queryString + secret) (الگوریتم قابل تنظیم)؛ create،
  buildJoinUrl، end، isMeetingRunning، getMeetingInfo، getRecordings، publishRecordings،
  deleteRecordings؛ URL encoding دقیق مطابق BBB؛ پارس XML؛ timeout از properties؛
  join URL و secret هرگز لاگ نشوند.
- BbbProvider پیاده‌سازی MeetingProvider (فقط سیم‌کشی به BbbClient؛ منطق جریان‌ها در تسک 15).
- تست واحد: checksum با مثال مستند BBB، URL encoding فارسی در name/fullName، پارس پاسخ
  SUCCESS/FAILED، create idempotent.
- mvn test پاس.

قبل از شروع، بخش «قوانین مشترک» در lms-integration/BBB_TASK_PROMPTS.md را بخوان و کامل رعایت کن
(به‌خصوص ثبت تاریخچه در "F:\project\clude doc\bbb" و به‌روزرسانی 00-INDEX.md).
```

## تسک 13 — config-service، compose و `.env.example` ریشه [کد]

```
تسک 13 از lms-integration/BBB_TASK_PROMPTS.md: بند «Config» در فاز ۴ lms-integration/BBB_INTEGRATION_PLAN.md.

- config-service/config-service/src/main/resources/db/changelog/dml/initial.sql: فقط یک
  changeset جدید در انتهای فایل با id با فرمت admin-dml:-YYYYMMDD-HHMM-NN (بعد از آخرین id
  موجود) که ردیف‌های virtual-classroom-service / dev برای virtual-classroom.provider و همه‌ی
  کلیدهای bbb.* را INSERT کند؛ مقادیر حساس با env placeholder مثل ${BBB_SHARED_SECRET:}.
  هیچ خط قبلی (به‌خصوص adobe.connect.*) تغییر نکند — بعد از ادیت با git diff ثابت کن فقط
  خطوط اضافه شده‌اند.
- docker-compose.yml و docker-compose-dev.yml: env های VIRTUAL_CLASS_PROVIDER، BBB_ENABLED،
  BBB_API_URL، BBB_SHARED_SECRET، BBB_CALLBACK_BASE_URL، BBB_CALLBACK_TOKEN برای
  virtual-classroom-service (ADOBE_* دست نخورد).
- .env.example ریشه (اگر هست) به‌روز شود.
- اگر می‌شود config-service را محلی بالا آورد، تأیید کن ValidationFailedException ندارد؛
  وگرنه در تاریخچه بنویس تست نشد.

قبل از شروع، بخش «قوانین مشترک» در lms-integration/BBB_TASK_PROMPTS.md را بخوان و کامل رعایت کن
(به‌خصوص ثبت تاریخچه در "F:\project\clude doc\bbb" و به‌روزرسانی 00-INDEX.md).
```

## تسک 14 — Schema (Liquibase سرویس) [کد]

```
تسک 14 از lms-integration/BBB_TASK_PROMPTS.md: بند «Schema (changeset جدید)» در فاز ۴
lms-integration/BBB_INTEGRATION_PLAN.md.

- virtual-classroom-service/.../db/changelog/ddl/initial.xml و master.xml را بخوان. changeset
  های قدیمی دست نخورند.
- changeset(ها)ی جدید (در فایل جدید ddl و include در master.xml، با همان context "ddl"):
  - virtual_meetings: provider (NVARCHAR(20)، NOT NULL، default 'ADOBE' برای ردیف‌های قدیمی)،
    external_meeting_id، last_started_at، record_video (BIT NULL).
  - جدول meeting_recordings با ستون‌های plan + status (PROCESSING/READY) + unique روی
    (record_id, format) + index روی meeting_id.
- entity ها و repository ها به‌روز؛ ProviderType enum.
- برای meeting جدید provider از config گرفته شود.
- mvn test پاس؛ اگر DB محلی هست، اجرای Liquibase را تأیید کن.

قبل از شروع، بخش «قوانین مشترک» در lms-integration/BBB_TASK_PROMPTS.md را بخوان و کامل رعایت کن
(به‌خصوص ثبت تاریخچه در "F:\project\clude doc\bbb" و به‌روزرسانی 00-INDEX.md).
```

## تسک 15 — جریان‌های start / join / end / settings [کد]

```
تسک 15 از lms-integration/BBB_TASK_PROMPTS.md: جریان استاد، جریان دانشجو، end و
PATCH /{classId}/settings در فاز ۴ lms-integration/BBB_INTEGRATION_PLAN.md.

- در course-service پیدا کن چطور مدرس یک CourseClass و ثبت‌نام دانشجو در کلاس مشخص می‌شود
  (CourseClass، ClassEnrollment و endpoint های موجود)؛ اگر endpoint داخلی مناسب نیست، طراحی
  حداقلی پیشنهاد و پیاده کن (با X-Internal-Token مثل الگوی موجود InternalServiceAuthFilter).
- POST /{classId}/start: فقط مدرس همان کلاس یا ADMIN؛ create idempotent با همه‌ی پارامترهای
  plan، شامل notifyRecordingIsOn=true + notifyRecordingAppend فارسی (T8) و
  meta_bbb-disable-recording-formats=video وقتی record_video (یا پیش‌فرض) false است (T7)؛
  welcome فارسی؛ خروجی join URL مدیر.
- GET /{classId}/join: چک ثبت‌نام؛ isMeetingRunning=false → 409 با پیام فارسی؛ join URL با
  role=VIEWER، userID، fullName (از security-service)، userdata-bbb_override_default_locale.
- POST /{classId}/end: چک مالکیت (رفع باگ فعلی که هر INSTRUCTOR هر کلاسی را end می‌کرد).
- PATCH /{classId}/settings: recordVideo.
- SecurityConfig به‌روز؛ endpoint قدیمی /participants برای Adobe بماند.
- تست‌های plan (مجوز 403 برای مدرس کلاس دیگر، پارامترهای create برای T7/T8).
- mvn test پاس.

قبل از شروع، بخش «قوانین مشترک» در lms-integration/BBB_TASK_PROMPTS.md را بخوان و کامل رعایت کن
(به‌خصوص ثبت تاریخچه در "F:\project\clude doc\bbb" و به‌روزرسانی 00-INDEX.md).
```

## تسک 16 — Callbackها و gateway [کد]

```
تسک 16 از lms-integration/BBB_TASK_PROMPTS.md: بند «Callbackها» در فاز ۴ lms-integration/BBB_INTEGRATION_PLAN.md.

- فرمت دقیق را از سورس bigbluebutton بخوان:
  record-and-playback/core/scripts/post_publish/post_publish_recording_ready_callback.rb
  (signed_parameters، JWT HS256) و
  record-and-playback/core/scripts/post_events/post_events_analytics_callback.rb
  (Authorization: Bearer، JWT HS512، ساختار payload).
- endpointها: callbacks/recording-ready، callbacks/analytics، callbacks/meeting-ended?token=
  با اعتبارسنجی امضا/توکن (مقایسه‌ی constant-time)، idempotent (callback تکراری ردیف تکراری
  نسازد).
- recording-ready: getRecordings → upsert در meeting_recordings به تفکیک format (presentation
  و video جدا می‌رسند، T7) → event کافکا RECORDING_READY.
- analytics: attendance_records (map userID → userId) → event ATTENDANCE_RECORDED.
- gateway: مسیرهای callback به RouteValidator.openApiEndpoints؛ SecurityConfig سرویس permitAll
  فقط برای همین مسیرها.
- تست: JWT معتبر/نامعتبر/منقضی، توکن غلط، callback تکراری.
- mvn test برای virtual-classroom-service و gateway-service پاس.

قبل از شروع، بخش «قوانین مشترک» در lms-integration/BBB_TASK_PROMPTS.md را بخوان و کامل رعایت کن
(به‌خصوص ثبت تاریخچه در "F:\project\clude doc\bbb" و به‌روزرسانی 00-INDEX.md).
```

## تسک 17 — recordings / attendance و notification-service [کد]

```
تسک 17 از lms-integration/BBB_TASK_PROMPTS.md: بندهای GET /{classId}/recordings، attendance و
notification-service در فاز ۴ lms-integration/BBB_INTEGRATION_PLAN.md.

- GET /{classId}/recordings از meeting_recordings: playback_url، video_url، status
  (PROCESSING/READY)، بدون video_url وقتی ویدئو برای آن اجرا خاموش بوده؛ فقط اعضای کلاس.
- حذف / unpublish ضبط: فقط مدرس کلاس یا ADMIN (BbbClient.deleteRecordings/publishRecordings).
- GET /{classId}/attendance برای BBB از attendance_records.
- notification-service: VirtualClassroomClient و AdaptiveRemediationConsumer — fullUrl دیگر لینک
  مستقیم BBB نباشد؛ لینک صفحه‌ی کلاس در فرانت LMS (base URL فرانت را از config موجود پیدا
  کن؛ اگر کلید config لازم است، فقط با changeset جدید طبق F:\omid\Lms_Micro_Git\LMS_MICRO\CLAUDE.md).
- معیار پذیرش فاز ۴ را تا جایی که بدون سرور BBB ممکن است (با mock) پوشش بده و بقیه را در
  تاریخچه «نیاز به سرور» بنویس.
- mvn test برای سرویس‌های تغییرکرده پاس.

قبل از شروع، بخش «قوانین مشترک» در lms-integration/BBB_TASK_PROMPTS.md را بخوان و کامل رعایت کن
(به‌خصوص ثبت تاریخچه در "F:\project\clude doc\bbb" و به‌روزرسانی 00-INDEX.md).
```

## تسک 18 — فرانت: hookها و پنل استاد [کد]

```
تسک 18 از lms-integration/BBB_TASK_PROMPTS.md: hookها و پنل استاد در فاز ۵ lms-integration/BBB_INTEGRATION_PLAN.md.

- frontend/CLAUDE.md و frontend/AGENTS.md و STEPS-TEACHING-PANEL.md را بخوان؛ الگوی hook ها
  و فراخوانی API موجود را دنبال کن.
- useStartClass، useJoinClass، useClassRecordings، useUpdateClassSettings.
- پنل استاد: دکمه‌ی «شروع کلاس آنلاین» (باز شدن در تب جدید)، «پایان کلاس»، نشانگر «در حال
  برگزاری»، سوییچ «ساخت فایل ویدئویی از ضبط» با متن توضیح plan (T7)، نکته‌ی ثابت «اسلاید را PDF
  آپلود کنید» (T4).
- npm run lint و npm run build (یا tsc) پاس؛ پیش‌نمایش در مرورگر داخلی با preview_start اگر
  launch.json هست، و اسکرین‌شات در تاریخچه توصیف شود.

قبل از شروع، بخش «قوانین مشترک» در lms-integration/BBB_TASK_PROMPTS.md را بخوان و کامل رعایت کن
(به‌خصوص ثبت تاریخچه در "F:\project\clude doc\bbb" و به‌روزرسانی 00-INDEX.md).
```

## تسک 19 — فرانت: ورود دانشجو، ضبط‌ها، حضور، صفحه‌ی خروج [کد]

```
تسک 19 از lms-integration/BBB_TASK_PROMPTS.md: بقیه‌ی فاز ۵ lms-integration/BBB_INTEGRATION_PLAN.md.

- frontend/src/components/panel/dashboard/live-session-banner.tsx: «ورود به کلاس» → useJoinClass؛
  409 → «کلاس هنوز توسط استاد شروع نشده» + تلاش خودکار هر ۳۰ ثانیه؛ کامنت قدیمی درباره‌ی
  نبود join-URL به‌روز شود.
- صفحه‌ی «ضبط‌های کلاس»: تاریخ شمسی (از lib/format موجود)، مدت، پخش، دانلود ویدئو، حالت «در حال
  آماده‌سازی فایل ویدئو»، عدم نمایش دانلود وقتی ویدئو خاموش بوده (T7)؛ حذف/مخفی برای استاد.
- صفحه‌ی حضور و غیاب برای استاد.
- صفحه‌ی مقصد logoutURL.
- lint و build پاس؛ پیش‌نمایش با mock یا بک‌اند محلی.

قبل از شروع، بخش «قوانین مشترک» در lms-integration/BBB_TASK_PROMPTS.md را بخوان و کامل رعایت کن
(به‌خصوص ثبت تاریخچه در "F:\project\clude doc\bbb" و به‌روزرسانی 00-INDEX.md).
```

## تسک 20 — نصب واقعی سرورها [سرور]

```
تسک 20 از lms-integration/BBB_TASK_PROMPTS.md: اجرای واقعی فاز ۱، ۱-ب و ۲ در
lms-integration/BBB_INTEGRATION_PLAN.md.

- من دستورها را روی سرورها اجرا می‌کنم و خروجی را برایت می‌فرستم. تو هر مرحله را قدم‌به‌قدم
  بگو، خروجی را بررسی کن و تا مرحله‌ی قبلی سالم نیست مرحله‌ی بعد را نده.
- ترتیب: سرور TURN (install-turn.sh، check-turn.sh) → سرور BBB (preflight.sh، install.sh) →
  تأیید apply-config → معیار پذیرش فاز ۱ و ۲ (گواهی، bbb-conf --check، API SUCCESS، df روی
  BBB_RECORDINGS_DIR، تست ۳ کاربر با relay، ضبط ۵ دقیقه‌ای در presentation و video).
- هر خطا: علت ریشه‌ای، اصلاح اسکریپت در lms-integration/deploy (نه دستکاری دستی روی سرور، T2).
- بعد از اتصال: BBB_API_URL و BBB_SHARED_SECRET را در .env سرور LMS ست کنم و تست end-to-end
  فاز ۴ (start → join → ضبط → end → recordings/attendance) را با هم انجام دهیم.
- هیچ secret ای را در تاریخچه ننویس.

قبل از شروع، بخش «قوانین مشترک» در lms-integration/BBB_TASK_PROMPTS.md را بخوان و کامل رعایت کن
(به‌خصوص ثبت تاریخچه در "F:\project\clude doc\bbb" و به‌روزرسانی 00-INDEX.md).
```

## تسک 21 — تست پذیرش مدیریت کلاس (فاز ۶) [سرور]

```
تسک 21 از lms-integration/BBB_TASK_PROMPTS.md: فاز ۶ و معیارهای پذیرش فاز ۳ و ۵ در
lms-integration/BBB_INTEGRATION_PLAN.md.

- برای هر آیتم فاز ۶ (شامل اعلان ضبط T8 و ویدئو خاموش T7) و معیارهای پذیرش فاز ۳ (بدون رشته‌ی
  انگلیسی در UI فارسی، RTL، تغییر زبان و برگشت، چت فارسی/مخلوط، اسلاید B Nazanin، بدون درخواست
  به دامنه‌ی خارجی) و فاز ۵ (سناریوی استاد + ۲ دانشجو فقط از UI LMS) یک سناریوی تست دقیق
  بنویس؛ من اجرا می‌کنم و نتیجه را می‌گویم.
- هر رشته‌ی انگلیسی یا ترجمه‌ی بد که پیدا شد: اصلاح در lms-integration/deploy/overrides/fa_IR.json + اجرای
  دوباره‌ی apply-config.
- نتیجه: lms-integration/deploy/ACCEPTANCE.md (جدول آیتم / نتیجه / توضیح) + خلاصه در تاریخچه.

قبل از شروع، بخش «قوانین مشترک» در lms-integration/BBB_TASK_PROMPTS.md را بخوان و کامل رعایت کن
(به‌خصوص ثبت تاریخچه در "F:\project\clude doc\bbb" و به‌روزرسانی 00-INDEX.md).
```

## تسک 22 — عملیات، پایداری، مستندات (فاز ۷) [کد + سرور]

```
تسک 22 از lms-integration/BBB_TASK_PROMPTS.md: فاز ۷ lms-integration/BBB_INTEGRATION_PLAN.md.

- lms-integration/deploy/tools/backup.sh: backup روزانه‌ی published (و raw اختیاری) به مقصد قابل تنظیم در
  .env (rsync)، با لاگ و کد خروج درست؛ نمونه‌ی cron.
- مانیتورینگ: پیشنهاد و تنظیم bbb-exporter یا حداقل اسکریپت هشدار دیسک/CPU و health check API.
- اندازه‌گیری پردازش ضبط (T7): راهنمای اندازه‌گیری کلاس ۹۰ دقیقه‌ای؛ نتایجی که من می‌دهم را در
  plan ثبت و طبق قاعده‌ی تصمیم plan، bbb.record-video-default و BBB_RAP_WORKERS را پیشنهاد کن
  (تغییر config فقط با changeset جدید).
- اعلان ضبط (T8) در متن قوانین/حریم خصوصی LMS در فرانت.
- lms-integration/deploy/README.md → runbook کامل (نصب، آپدیت، تغییر secret، جابه‌جایی دیسک، عیب‌یابی).
- به‌روزرسانی docs/DEPLOYMENT.md و docs/ARCHITECTURE.md (Adobe → BBB، با ذکر اینکه Adobe به
  عنوان provider جایگزین باقی است).

قبل از شروع، بخش «قوانین مشترک» در lms-integration/BBB_TASK_PROMPTS.md را بخوان و کامل رعایت کن
(به‌خصوص ثبت تاریخچه در "F:\project\clude doc\bbb" و به‌روزرسانی 00-INDEX.md).
```

## تسک 23 — جمع‌بندی و آرشیو پرامپت‌ها [کد] (آخرین تسک)

```
تسک 23 (آخرین) از lms-integration/BBB_TASK_PROMPTS.md: جمع‌بندی.

- "F:\project\clude doc\bbb\00-INDEX.md" را بخوان و بررسی کن برای همه‌ی تسک‌های 00 تا 22
  فایل تاریخچه هست؛ هر تسک ناقص یا بدون تاریخچه را لیست کن.
- lms-integration/BBB_INTEGRATION_PLAN.md: هر چک‌باکس [ ] باقی‌مانده را با دلیلش گزارش کن.
- این فایل (lms-integration/BBB_TASK_PROMPTS.md) را بدون تغییر در
  "F:\project\clude doc\bbb\BBB_TASK_PROMPTS.md" کپی کن، و lms-integration/BBB_INTEGRATION_PLAN.md را هم
  در "F:\project\clude doc\bbb\BBB_INTEGRATION_PLAN.md".
- فایل تاریخچه‌ی همین تسک (YYYY-MM-DD-bbb-23-summary.md) شامل: خلاصه‌ی کل پروژه، لیست
  فایل‌های ساخته/تغییر داده‌شده، کارهای باقی‌مانده، و لینک به دو فایل کپی‌شده.
- خط آخر 00-INDEX.md.

قبل از شروع، بخش «قوانین مشترک» در lms-integration/BBB_TASK_PROMPTS.md را بخوان و کامل رعایت کن
(به‌خصوص ثبت تاریخچه در "F:\project\clude doc\bbb" و به‌روزرسانی 00-INDEX.md).
```
