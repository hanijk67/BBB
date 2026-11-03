# نقشه‌ی راه: راه‌اندازی BigBlueButton و اتصال به LMS

> سند مرحله‌به‌مرحله. هر مرحله یک چک‌لیست `- [ ]` و یک «معیار پذیرش» دارد. ترتیب
> فازها مهم است؛ داخل هر فاز، مراحلی که وابستگی ندارند را می‌شود موازی جلو برد.
>
> سورس BBB در `F:\omid\Lms_Micro_Git\bigbluebutton` (برنچ `v4.0.x-develop`) فقط
> برای **مرجع + کار ترجمه‌ی فارسی** استفاده می‌شود. خود سرور از **پکیج/ایمیج رسمی**
> نصب می‌شود، نه build از سورس.
>
> **مسیرها:** این فایل و `lms-integration/...` در پروژه‌ی BBB
> (`F:\omid\Lms_Micro_Git\bigbluebutton`) هستند. مسیرهای کد LMS (`virtual-classroom-service/`،
> `config-service/`، `gateway-service/`، `frontend/`، `docker-compose.yml`، `docs/...`، `CLAUDE.md`)
> نسبت به `F:\omid\Lms_Micro_Git\LMS_MICRO` هستند.

## تصمیم‌های تأییدشده

| # | تصمیم | کجا اجرا می‌شود |
|---|---|---|
| T1 | نصب رسمی `bbb-install.sh` روی Ubuntu 24.04 + لایه‌ی config خودمان که همه‌چیز را از `.env` می‌خواند (نه docker community، نه build از سورس) | فاز ۰ (D2)، فاز ۲ |
| T2 | BBB را fork/build نمی‌کنیم. هر سفارشی‌سازی (ترجمه، CSS، فونت، config) فقط به صورت فایل overlay که `apply-config.sh` اعمالش می‌کند. ترجمه‌ی فارسی به Transifex خود BBB هم ارسال می‌شود | فاز ۲، فاز ۳ |
| T3 | TURN جدا (coturn) روی یک VPS کوچک با IP جدا، روی TCP/TLS 443 | فاز ۱، فاز ۲ |
| T4 | اسلاید فارسی: فونت فارسی روی host نصب می‌شود (کانتینر LibreOffice فونت‌های host را mount می‌کند) + alias فونت‌های رایج ایرانی + توصیه‌ی PDF به استاد | فاز ۳، فاز ۵ |
| T5 | همه‌ی فونت‌ها و assetهای کلاینت روی خود سرور BBB self-host می‌شوند؛ هیچ CDN خارجی | فاز ۳ |
| T6 | Adobe حذف نمی‌شود: `MeetingProvider` با انتخاب `BBB\|ADOBE` (پیش‌فرض `BBB`) | فاز ۴ |
| T7 | هر دو فرمت ضبط (`presentation` + `video`) فعال؛ ساخت video برای هر کلاس قابل خاموش‌کردن (`meta_bbb-disable-recording-formats`)؛ زمان پردازش اندازه‌گیری می‌شود | فاز ۲، فاز ۴، فاز ۷ |
| T8 | اعلان ضبط به شرکت‌کننده‌ها (`notifyRecordingIsOn=true`) | فاز ۴، فاز ۶ |

---

## وضعیت فعلی (بررسی‌شده)

**سمت BBB (سورس موجود):**
- چندزبانه **از قبل وجود دارد**: ۶۳ زبان در `bigbluebutton-html5/public/locales/`. کاربر از
  Settings → Application → Language زبان را عوض می‌کند (`showAllAvailableLocales: true`).
- فایل فارسی **وجود دارد**: `fa_IR.json` (با نام «فارسی» در `settings.yml`). RTL خودکار
  است (`RTL_LANGUAGES = ['ar','dv','fa','he']` در `imports/startup/client/intlAdapter.tsx`).
- **کمبود ترجمه:** `en.json` = ۱۸۴۲ کلید، `fa_IR.json` = ۱۵۷۶ کلید → **۳۴۵ کلید ترجمه
  نشده** (به انگلیسی fallback می‌شوند) + ۷۹ کلید منسوخ. بیشترین کمبود:
  learningDashboard (۴۹)، createBreakoutRoom (۳۸)، **chat (۳۰ از ۸۸)**، notes (۲۵)،
  userList (۲۵)، lock-viewers (۲۰)، poll (۱۹)، appsGallery (۱۴)، timer (۱۱)، settings (۱۱).
- وایت‌برد (`public/tldraw/translations/fa.json`) و پلیر ضبط (`bbb-playback` نسخه‌ی
  v5.4.8 → `fa_IR.json`) فارسی دارند. `bigbluebutton-web/grails-app/i18n` فارسی ندارد
  (فقط صفحات خطا/سرور؛ اولویت پایین).
- چت عمومی/خصوصی، قفل چت توسط استاد، پین پیام، ضبط با دکمه‌ی Start/Stop، اتاق انتظار،
  breakout، نظرسنجی، تایمر، یادداشت مشترک، Learning Dashboard — **همه built-in هستند**.
- **داکر:** BBB 4.0 رسمی با `bbb-install.sh` روی Ubuntu 24.04 نصب می‌شود (پکیج deb؛ فقط
  LibreOffice داخل docker است). پروژه‌ی داکری community (`github.com/bigbluebutton/docker`)
  فقط BBB **3.0** است و طبق README خودش LiveKit و NAT در آن «missing / broken» است.
  (در 4.0 مدیا پیش‌فرض LiveKit است.) → تصمیم D2 پایین.

**سمت LMS:**
- `virtual-classroom-service` فعلاً برای **Adobe Connect** نوشته شده
  (`AdobeConnectClient`, `AdobeConnectProperties`, کلیدهای `adobe.connect.*` در
  config-service). مدل: یک meeting به ازای هر `lmsClassId` (unique constraint).
- API فعلی: `POST/GET /{classId}/meeting`, `POST /{classId}/participants`,
  `GET /{classId}/join`, `POST /{classId}/end`, `GET /{classId}/attendance`,
  `GET /{classId}/recordings` — زیر `/api/v1/virtual-classes/**` روی gateway.
- `notification-service` → `VirtualClassroomClient.provisionMeeting()` از `fullUrl` استفاده
  می‌کند (برای کلاس جبرانی).
- فرانت: `live-session-banner.tsx` دکمه‌ی «ورود به کلاس» دارد ولی **به سرویس کلاس مجازی
  وصل نیست** (به course player لینک می‌دهد).
- مشکل امنیتی موجود: هر `INSTRUCTOR` می‌تواند meeting هر کلاسی را `end` کند (چک مالکیت نیست).

---

## فاز ۰ — تصمیم‌ها (قبل از هر کاری)

- [x] **D1 — نسخه‌ی BBB → 4.0 (تأیید شد ۲۰۲۶-۱۰-۲۷).** صفحه‌ی Releases گیت‌هاب: `v4.0.0`
  (۱۴ اکتبر) برچسب Latest دارد؛ آخرین 3.0 = `v3.0.39`. → `BBB_VERSION=noble-400`، Ubuntu 24.04.
- [x] **D2 — روش استقرار → الف (تأیید شد، T1).**
  - **الف (انتخاب‌شده):** `bbb-install.sh` رسمی روی Ubuntu 24.04 تمیز + یک لایه‌ی config
    خودمان که همه‌چیز را از `.env` می‌خواند (`lms-integration/deploy/`، فاز ۲). پشتیبانی رسمی، LiveKit،
    آپدیت ساده.
  - **ب (رد):** `bigbluebutton/docker` (community، فقط 3.0، بدون LiveKit/NAT).
  - **ج (رد، T2):** ساخت ایمیج از سورس — ده‌ها کامپوننت (akka/scala، freeswitch، livekit،
    graphql/hasura، postgres، redis، html5، bbb-web، recording) → نگهداری سنگین.
  - نکته: یکپارچگی با LMS از طریق HTTP API است؛ روش نصب **روی کد LMS اثری ندارد**.
- [x] **D3 — فرمت ضبط → هر دو (تأیید شد، T7).** `presentation` (پلیر HTML با
  اسلاید/چت/وایت‌برد) + `video` (یک فایل ویدئویی mp4 قابل دانلود). ساخت video برای هر
  کلاس قابل خاموش‌کردن است (فاز ۴).
- [x] **D4 — دامنه → `class.glmp.ir` (BBB) و `turn.glmp.ir` (TURN) (تأیید شد ۲۰۲۶-۱۰-۲۷).**
  BBB **حتماً** HTTPS با گواهی معتبر می‌خواهد (WebRTC بدون secure context کار نمی‌کند)؛ رکورد A
  هر دو روی IP سرور مربوط.
- [ ] **D5 — ظرفیت.** حداکثر کلاس هم‌زمان × حداکثر نفر در هر کلاس × چند وبکم؟
  (برای سایزینگ CPU/پهنای باند/دیسک.)
  **هنوز باز** — جواب داده نشده؛ تا آن موقع حداقل production فاز ۱ (8 هسته / 16GB) مبنا است.

**معیار پذیرش:** D1..D5 مکتوب شده (همین فایل به‌روز شود).

---

## فاز ۱ — آماده‌سازی سرور

- [ ] Ubuntu 24.04 64-bit تمیز (بدون apache/nginx/panel)، کرنل 6.x.
- [ ] حداقل production: **8 هسته‌ی CPU dedicated، 16GB RAM + swap**، دیسک جدا برای ضبط
  (مستند رسمی: 500GB اگر ضبط فعال باشد). برای تست: 4 هسته / 8GB.
- [ ] IP عمومی ثابت. اگر سرور پشت NAT است → `bbb-install.sh` با سوییچ‌های مخصوص NAT
  (مستند `install.md`).
- [ ] فایروال: TCP `80, 443` و UDP `16384-32768` باز. پورت 80/443 توسط چیز دیگری اشغال نباشد.
- [ ] DNS: `class.glmp.ir → <BBB_IP>` و انتشار کامل (`dig +short class.glmp.ir`).
- [ ] IPv6: اگر `inet6 ::1/128` نیست → بعد از نصب، IPv6 را در FreeSWITCH خاموش کن
  (مستند troubleshooting).
- [ ] **شبکه‌ی ایران:** دسترسی سرور به `ubuntu.bigbluebutton.org`، Docker Hub (برای ایمیج
  LibreOffice) و Let's Encrypt را تست کن. اگر Docker Hub بسته است → registry mirror در
  `/etc/docker/daemon.json` (مقدار از `.env`: `DOCKER_REGISTRY_MIRROR`).
### ۱-ب — سرور TURN جدا (T3)

> دلیل: دانشجوهایی که روی اینترنت موبایل یا شبکه‌ی محدود هستند و UDP ندارند، بدون TURN روی
> TCP/TLS 443 صدا و تصویر ندارند. TURN باید پورت 443 را **انحصاری** داشته باشد، پس روی
> سرور BBB (که nginx روی 443 دارد) نصب نمی‌شود.

- [ ] یک VPS کوچک (مثلاً 1–2 هسته، 1–2GB RAM؛ CPU-bound نیست ولی پهنای‌باند relay می‌خواهد)،
  Ubuntu 24.04 تمیز، **IP عمومی جدا**.
- [ ] DNS: `turn.glmp.ir → <TURN_IP>`.
- [ ] فایروال TURN: TCP/UDP `3478`، TCP/UDP `443`، UDP `32769-65535` (relay) + `22`.
- [ ] secret: رشته‌ی تصادفی ۸–۱۶ کاراکتری → `BBB_TURN_SECRET` در `.env` هر دو سرور.
- [ ] نصب روی سرور TURN با همان اسکریپت رسمی (بدون `-v`): — `deploy/install-turn.sh` (تسک 02).
  **یافته (تسک 02):** `bbb-install.sh` برنچ v4.0.x-release در این حالت secret ورودی را نادیده می‌گیرد
  (تصادفی می‌سازد)، TLS/443 و گواهی را تنظیم نمی‌کند و relay را فقط به IP خود سرور TURN مجاز می‌کند؛
  پس `install-turn.sh` بعد از آن `turnserver.conf` را طبق `turn-server.md` کامل می‌کند.
  ```bash
  ./bbb-install.sh -c "$BBB_TURN_HOST:$BBB_TURN_SECRET" -e "$BBB_LETSENCRYPT_EMAIL"
  ```
  (کانفیگ: `/etc/turnserver.conf`؛ گواهی Let's Encrypt با renewal-hook برای کاربر `turnserver` —
  مستند `docs/docs/administration/turn-server.md` در سورس.)
- [ ] در فاز ۲، نصب BBB با `-c "$BBB_TURN_HOST:$BBB_TURN_SECRET"` → bbb-web لیست TURN را در
  `/etc/bigbluebutton/turn-stun-servers.xml` به مرورگر می‌دهد.
- [ ] تست: در Firefox `about:webrtc` (یا Chrome `chrome://webrtc-internals`) کاندید نوع `relay`
  دیده شود؛ سناریوی واقعی: یک کلاینت که UDP خروجی‌اش بسته است (فایروال لپ‌تاپ یا اینترنت
  موبایل) صدا/تصویر بگیرد.

**معیار پذیرش:** `free -h` ≥ 15G، `nproc` ≥ 8، پورت‌ها از بیرون باز (`nc -vzu`)، DNS هر دو
دامنه درست، سرور TURN با گواهی معتبر روی 443 گوش می‌دهد.

---

## فاز ۲ — نصب BBB با پیکربندی از `.env`

پوشه‌ی جدید در پروژه‌ی BBB: `lms-integration/deploy/` شامل:

| فایل | نقش |
|---|---|
| `.env.example` | همه‌ی متغیرها (پایین) — `.env` واقعی commit نشود |
| `install.sh` | `.env` را می‌خواند، دیسک ضبط را mount می‌کند، `bbb-install.sh` را اجرا می‌کند |
| `apply-config.sh` | کپی به `/etc/bigbluebutton/bbb-conf/apply-config.sh` — بعد از هر آپدیت/ری‌استارت دوباره تنظیمات را اعمال می‌کند |
| `overrides/fa_IR.json` | ترجمه‌ی کامل فارسی (فاز ۳) |
| `overrides/assets/custom.css` + `overrides/assets/fonts/*.woff2` | فونت فارسی کلاینت + جهت متن چت، self-host (فاز ۳، T5) |
| `overrides/fonts/*.ttf` + `overrides/fonts/99-lms-fa.conf` | فونت فارسی برای تبدیل اسلاید در LibreOffice + alias فونت‌های ایرانی (فاز ۳، T4) |
| `overrides/recording.yml` | فعال‌سازی فرمت‌های ضبط (T7) |

- [x] **متغیرهای `.env`:** (تسک 01: `deploy/.env.example` + `deploy/lib/env.sh`؛ اضافه‌شده: `BBB_INSTALL_BRANCH`، `BBB_TURN_PUBLIC_IP`)
  ```env
  BBB_DOMAIN=class.glmp.ir
  BBB_PUBLIC_IP=
  BBB_LETSENCRYPT_EMAIL=
  BBB_VERSION=noble-400            # سوییچ -v در bbb-install (README برنچ v4.0.x-release)
  BBB_SHARED_SECRET=               # openssl rand -hex 32 — همین در LMS هم ست می‌شود
  BBB_RECORDINGS_DIR=/data/bigbluebutton   # کل /var/bigbluebutton اینجا می‌رود
  BBB_RECORDING_FORMATS=presentation,video   # T7
  BBB_VIDEO_MP4=true               # خروجی H.264 برای iOS
  BBB_RAP_WORKERS=1                # تعداد worker پردازش ضبط (فاز ۷ اندازه‌گیری می‌شود)
  BBB_RAW_RETENTION_DAYS=14        # پاک‌سازی raw؛ published نگه داشته می‌شود
  BBB_DEFAULT_LOCALE=fa-IR         # overrideLocale در bbb-html5.yml (خالی = زبان مرورگر)
  BBB_FALLBACK_LOCALE=en
  BBB_DEFAULT_GUEST_POLICY=ALWAYS_ACCEPT
  BBB_ALLOWED_CALLBACK_HOSTS=      # فقط اگر LMS روی IP خصوصی است (fetchUrlAllowedLocalHosts)
  BBB_TURN_HOST=turn.glmp.ir       # T3 — سرور جدا
  BBB_TURN_SECRET=                 # ۸–۱۶ کاراکتر تصادفی؛ روی هر دو سرور یکی
  BBB_FONTS_DIR=/usr/share/fonts/truetype/lms-fa   # T4/T5 — فونت‌های فارسی روی host
  BBB_CUSTOM_ASSETS_URL=/lms-assets               # T5 — CSS و فونت self-host روی nginx خود BBB
  DOCKER_REGISTRY_MIRROR=
  ```
- [ ] **مسیر ضبط از `.env`** (قبل یا بلافاصله بعد از نصب، با سرویس‌های متوقف): — اسکریپت آماده
  (مرحله ۴ `install.sh`، idempotent + چک فضای دیسک، تسک 03)؛ اجرا در تسک 20.
  ```bash
  set -a; . ./.env; set +a
  bbb-conf --stop
  mkdir -p "$BBB_RECORDINGS_DIR"
  rsync -a /var/bigbluebutton/ "$BBB_RECORDINGS_DIR"/
  mv /var/bigbluebutton /var/bigbluebutton.orig && mkdir /var/bigbluebutton
  echo "$BBB_RECORDINGS_DIR /var/bigbluebutton none bind 0 0" >> /etc/fstab
  mount /var/bigbluebutton
  bbb-conf --start
  ```
  (bind mount به جای symlink مستند رسمی؛ هر دو کار می‌کنند.)
- [ ] اجرای `bbb-install.sh` (برنچ `v4.0.x-release`) از داخل `install.sh`: — اسکریپت آماده (تسک 03)؛
  اجرا در تسک 20.
  ```bash
  ./bbb-install.sh -v "$BBB_VERSION" -s "$BBB_DOMAIN" -e "$BBB_LETSENCRYPT_EMAIL" \
                   -c "$BBB_TURN_HOST:$BBB_TURN_SECRET"
  ```
  **بدون** Greenlight (`-g` نزن؛ رابط کاربری ما LMS است).
- [ ] **قانون T2:** هیچ فایلی روی سرور دستی ادیت نشود. هر تغییر = فایل در `lms-integration/deploy/overrides/`
  + یک خط در `apply-config.sh`. چون `apply-config.sh` بعد از هر `bbb-install.sh`/آپدیت پکیج و هر
  `bbb-conf --restart` اجرا می‌شود، آپدیت BBB سفارشی‌سازی‌ها را پاک نمی‌کند.
- [ ] secret: `bbb-conf --secret` → مقدار را با `BBB_SHARED_SECRET` یکی کن (override در
  `/etc/bigbluebutton/bbb-web.properties`: `securitySalt=`). secret پیش‌فرض داخل سورس
  (`330a8b08...`) هرگز استفاده نشود.
- [x] `apply-config.sh` این‌ها را اعمال کند: (تسک 04؛ نکته‌های تأییدشده از سورس: video در 4.0
  به‌صورت پیش‌فرض mp4/m4v می‌سازد پس `video.yml` تغییر نمی‌کند؛ retention با `published_days` در
  `/etc/default/bigbluebutton-cron-config` که cron.daily خودش source می‌کند، بدون ادیت cron؛ assetها در
  `/var/www/bigbluebutton-default/assets/lms-assets/` = root `location /` در nginx؛ `enableUFWRules`
  پیش‌فرض bbb-install حفظ شد)
  - `/etc/bigbluebutton/bbb-web.properties`: `securitySalt`, `defaultGuestPolicy`,
    `disableRecordingDefault=false`, `autoStartRecording=false`, `allowStartStopRecording=true`,
    `fetchUrlAllowedLocalHosts` (در صورت نیاز).
  - `/etc/bigbluebutton/bbb-html5.yml`: `public.app.defaultSettings.application.overrideLocale`,
    `fallbackLocale`, `public.app.customStyleUrl` (از طریق `yq`).
  - **ضبط (T7):** `/etc/bigbluebutton/recording/recording.yml` با هر دو فرمت:
    ```yml
    steps:
      archive: "sanity"
      sanity: "captions"
      captions:
        - "process:presentation"
        - "process:video"
      "process:presentation": "publish:presentation"
      "process:video": "publish:video"
    ```
    + `apt install -y bbb-playback-video` + فعال‌کردن mp4 در `video.yml`/`presentation.yml`
    (`/usr/local/bigbluebutton/core/scripts/`) + تعداد worker از `BBB_RAP_WORKERS`
    (`systemctl edit bbb-rap-resque-worker.service` → `Environment=COUNT=N`؛ هشدار مستند: اگر
    `defaultKeepEvents`/`meetingKeepEvents` روشن است COUNT بالاتر از ۱ نشود) →
    `systemctl restart bbb-rap-resque-worker`.
  - کپی `overrides/fa_IR.json` روی فایل locale کلاینت html5 (مسیر نصب:
    `/usr/share/bigbluebutton/html5-client/` — زیرپوشه‌ی `locales` را با `ls` تأیید کن).
  - **فونت‌ها (T4/T5):** کپی `overrides/fonts/*` به `BBB_FONTS_DIR` + `overrides/fonts/99-lms-fa.conf`
    به `/etc/fonts/conf.d/` + `fc-cache -f` (جزئیات فاز ۳).
  - **assetهای self-host (T5):** کپی `overrides/assets/` (custom.css + فونت‌های woff2) به
    `/var/www/bigbluebutton-default/assets/lms/` (یا پوشه‌ای که nginx خود BBB سرو می‌کند؛ مسیر
    را روی سرور تأیید کن) → `customStyleUrl=https://$BBB_DOMAIN$BBB_CUSTOM_ASSETS_URL/custom.css`.
  - پاک‌سازی raw قدیمی‌تر از `BBB_RAW_RETENTION_DAYS` (cron موجود
    `/etc/cron.daily/bigbluebutton`).
- [ ] `bbb-conf --restart` و بعد `bbb-conf --check` (بدون warning).

**معیار پذیرش:** `https://class.glmp.ir` گواهی معتبر؛ `bbb-conf --check` تمیز؛
`https://class.glmp.ir/bigbluebutton/api` پاسخ `<returncode>SUCCESS</returncode>`؛
`df -h /var/bigbluebutton` روی دیسک `BBB_RECORDINGS_DIR` است؛ یک کلاس تستی با API-Mate یا
curl ساخته و با ۳ کاربر (یکی روی موبایل دیتا، یکی با UDP بسته → کاندید `relay` از TURN)
صدا/تصویر/اشتراک صفحه کار می‌کند؛ یک ضبط ۵ دقیقه‌ای هم در `published/presentation` و هم در
`published/video` (فایل mp4) ظاهر می‌شود.

---

## فاز ۳ — فارسی کامل + چندزبانه

> چندزبانه از قبل کار می‌کند؛ این فاز «کامل کردن فارسی» و «فارسی پیش‌فرض ولی قابل تغییر» است.

- [x] **اسکریپت diff کلیدها** (`lms-integration/deploy/tools/locale-diff.py`): از `en.json` و `fa_IR.json`
  در سورس، فایل `missing_fa.json` (۳۴۵ کلید با متن انگلیسی) و لیست ۷۹ کلید منسوخ بسازد.
- [x] ترجمه‌ی ۳۴۵ کلید (تسک 06: ۱۲۵ کلید اولویت ۱، تسک 07: ۲۲۰ کلید اولویت ۲ + اصلاح ۱۱ ترجمه‌ی
  قدیمی با placeholder غلط) — **اولویت ۱:** `app.chat.*` (۳۰)، `app.userList.*`، `app.lock-viewers.*`،
  `app.recording.*`، `app.audio.*`، `app.actionsBar.*`، `app.guest.*` (هر چیزی که در کلاس
  عادی دیده می‌شود). **اولویت ۲:** breakout، poll، timer، notes، learningDashboard، بقیه.
  - placeholderها (`{0}`, `{name}`, ...) و تگ‌ها دست نخورند؛ اصطلاحات یکدست (glossary: ارائه‌دهنده،
    مدیر جلسه، شرکت‌کننده، اتاق جانبی، ...).
- [x] merge به `lms-integration/deploy/overrides/fa_IR.json` (کلیدهای منسوخ حذف) + اعتبارسنجی JSON +
  اسکریپت چک که هیچ کلید `en` جا نیفتاده باشد.
- [ ] **ارسال ترجمه به Transifex خود BBB (T2):** حساب در transifex.com → عضویت در تیم فارسی
  پروژه‌ی [BigBlueButton](https://app.transifex.com/bigbluebutton/) → وارد کردن همان ۳۴۵ ترجمه.
  Transifex با GitHub یکپارچه است (`transifex.yml`: منبع `bigbluebutton-html5/public/locales/en.json`)
  و فایل کامل‌شده را با PR خودکار وارد ریلیز بعدی می‌کند (مستند
  `docs/docs/development/localization.md`). هدف: بعد از چند ریلیز، overlay ما دیگر لازم نباشد.
- [ ] **بعد از هر آپدیت BBB:** دوباره `locale-diff.py` روی `en.json` نسخه‌ی جدید اجرا شود
  (کلیدهای تازه) → ترجمه → هم overlay هم Transifex.
- [x] **زبان پیش‌فرض:** (تسک 15) LMS در لینک join پارامتر `userdata-bbb_override_default_locale=<زبان کاربر در LMS>`
  (پیش‌فرض `fa-IR`) می‌فرستد. کاربر داخل کلاس همچنان از Settings هر زبان دیگری را
  انتخاب می‌کند. (`overrideLocale` سراسری در `bbb-html5.yml` فقط اگر بخواهیم بدون LMS هم
  فارسی باز شود.)
- [x] **فونت فارسی کلاینت، self-host (T5):** (تسک 08: Vazirmatn v33.003، Regular/Medium/Bold؛ تست
  Network روی سرور در تسک 21)
  - Vazirmatn (لایسنس OFL) را از ریلیز رسمی‌اش یک بار دانلود و فایل‌های `woff2` را داخل
    `lms-integration/deploy/overrides/assets/fonts/` در ریپو commit کن (نسخه ثابت، نه دانلود موقع نصب).
  - `custom.css` با `@font-face` که فقط به `url(./fonts/...)` روی دامنه‌ی خود BBB اشاره می‌کند +
    `font-family` برای `[dir="rtl"]` و `html[lang^="fa"]` → بارگذاری از `customStyleUrl`.
  - **هیچ** آدرس خارجی (Google Fonts، jsDelivr، unpkg، ...) در CSS یا config نباشد. چک: در
    DevTools → Network، فیلتر domain غیر از `class.glmp.ir` و `turn.glmp.ir` باید خالی باشد.
- [x] **جهت متن چت:** (تسک 08: selector پایدار `[data-test="messageContent"]`،
  `[data-test="chatMessageReplied"]`، `#message-input`؛ تست روی سرور در تسک 21) پیام فارسی در UI انگلیسی (یا برعکس) باید درست نمایش داده شود →
  در `custom.css` برای متن پیام‌ها `unicode-bidi: plaintext; text-align: start;` (selector
  دقیق را از DOM کلاینت پیدا کن). تست: پیام فارسی، انگلیسی، مخلوط، با عدد و لینک.
- [x] **اسلاید فارسی (T4):** (تسک 09: mount فونت host در `convert-local.sh` تأیید شد —
  `/usr/share/fonts`، `/usr/share/fontconfig`، `/etc/fonts`، `/var/cache/fontconfig` همه `:ro`؛ تست
  واقعی طبق `deploy/tools/test-slides/README.md` در تسک 21) PPTX/DOCX فارسی بدون فونت فارسی در LibreOffice خراب تبدیل می‌شود.
  کانتینر `bbb-soffice` فونت‌های host را read-only mount می‌کند
  (`-v /usr/share/fonts/:/usr/share/fonts/:ro` و `/etc/fonts/` در
  `bbb-libreoffice/assets/convert-local.sh`) → **ایمیج سفارشی لازم نیست**، فونت روی host کافی است:
  - فایل‌های `ttf` فونت‌های آزاد (Vazirmatn، و در صورت نیاز Sahel/Shabnam/Samim — همه OFL) در
    `lms-integration/deploy/overrides/fonts/` → کپی به `BBB_FONTS_DIR` + `fc-cache -f`.
  - `99-lms-fa.conf` (fontconfig alias): فونت‌های رایج در اسلایدهای ایرانی که لایسنس آزاد ندارند
    (`B Nazanin`, `B Titr`, `B Mitra`, `B Lotus`, `B Yekan`, `IRANSans`, `Tahoma`) → جایگزین
    Vazirmatn، تا متن به جای مربع/حروف جدا با فونت فارسی رندر شود. فونت‌های غیرآزاد روی سرور
    نصب نشوند.
  - تست: یک PPTX با B Nazanin + یک DOCX فارسی + یک PDF آپلود شود؛ متن متصل، راست‌به‌چپ، بدون
    مربع. اگر چیدمان (طول خط/شکست سطر) به‌خاطر جایگزینی فونت به‌هم ریخت → توصیه‌ی PDF (فاز ۵).
  - توصیه به استاد (فاز ۵): «برای حفظ دقیق فونت و چیدمان، اسلاید را PDF کنید» — PDF فونت را
    embed دارد و از LibreOffice رد نمی‌شود.
- [x] پیام خوش‌آمد فارسی: از طرف LMS در پارامتر `welcome` همان `create` ارسال شود. (تسک 15: `bbb.welcome`)
- [ ] (اولویت پایین) `messages_fa.properties` برای `bigbluebutton-web`.

**معیار پذیرش:** با زبان فارسی، در کل UI کلاس (به‌خصوص چت، لیست کاربران، قفل‌ها، ضبط) هیچ
رشته‌ی انگلیسی دیده نشود؛ RTL درست؛ تغییر زبان به en/de/... از Settings و برگشت به فارسی کار
کند؛ پیام فارسی/مخلوط در چت درست چیده شود؛ اسلاید PPTX فارسی (با فونت B Nazanin) سالم
تبدیل شود؛ در Network هیچ درخواستی به دامنه‌ی خارجی (فونت/CDN) نباشد.

---

## فاز ۴ — بازنویسی `virtual-classroom-service` برای BBB

> قانون پروژه (CLAUDE.md): کلیدهای config جدید فقط با **changeset جدید در انتهای**
> `config-service/.../dml/initial.sql`؛ ردیف‌های `adobe.connect.*` دست نخورند. در
> Liquibase خود سرویس هم فقط changeset جدید.

- [x] **Provider abstraction (T6) — Adobe حذف نمی‌شود:** (تسک 11؛ انتخاب با `MeetingProviderRegistry` به‌جای
  `@ConditionalOnProperty` تا meetingهای provider دیگر بعد از سوییچ نشکنند — دلیل در تاریخچه‌ی تسک 11)
  - اینترفیس `MeetingProvider` (create/start, joinUrl, end, isRunning, meetingInfo, recordings,
    attendance) با دو پیاده‌سازی: `AdobeConnectProvider` (منطق فعلی `AdobeConnectClient`
    بدون تغییر رفتار، فقط پشت اینترفیس) و `BbbProvider`.
  - انتخاب با `virtual-classroom.provider=BBB|ADOBE` — **پیش‌فرض `BBB`**؛ bean با
    `@ConditionalOnProperty`.
  - `VirtualClassroomServiceImpl` فقط به `MeetingProvider` وابسته باشد، نه به هیچ client مشخصی.
  - ستون `provider` در `virtual_meetings`: meeting قدیمی با همان provider که ساخته شده ادامه
    می‌دهد (سوییچ provider meetingهای قبلی را نمی‌شکند).
  - کلیدهای `adobe.connect.*` و env های `ADOBE_*` در compose دست نخورند.
  - تست‌های فعلی Adobe بدون تغییر رفتار پاس شوند.
- [x] **`BbbProperties`** (تسک 12) (`@ConfigurationProperties("bbb")`): `enabled`, `base-url`
  (`https://class.glmp.ir/bigbluebutton/api`), `shared-secret`, `checksum-algorithm=sha256`,
  `default-locale=fa-IR`, `callback-base-url`, `callback-token`, `record=true`,
  `mute-on-start`, `guest-policy`, `logout-url`, timeouts، و:
  - `record-video-default=true` (T7)
  - `notify-recording-is-on=true` و `notify-recording-append` (T8، متن فارسی)
- [x] **`BbbClient`:** (تسک 12؛ بردار تست SHA-1 مستند api.md پاس) checksum = `sha256(callName + queryString + secret)`؛ متدهای `create`,
  `buildJoinUrl`, `end`, `isMeetingRunning`, `getMeetingInfo`, `getRecordings`,
  `publishRecordings`, `deleteRecordings`؛ پارس XML پاسخ؛ تست واحد برای checksum با بردار
  تست مستند BBB.
- [x] **Config:** (تسک 13: `admin-dml:-20261027-0001-01`؛ git diff: ۲۶ خط اضافه، ۰ حذف) changeset جدید `admin-dml:-YYYYMMDD-HHMM-NN` با کلیدهای `bbb.*` و
  `virtual-classroom.provider` (مقادیر از env placeholder، مثل `${BBB_SHARED_SECRET:}`).
  env در `docker-compose.yml` و `.env.example` ریشه: `VIRTUAL_CLASS_PROVIDER`, `BBB_ENABLED`,
  `BBB_API_URL`, `BBB_SHARED_SECRET`, `BBB_CALLBACK_BASE_URL`, `BBB_CALLBACK_TOKEN`.
- [x] **Schema (changeset جدید):** (تسک 14: `ddl/bbb-provider.xml`، VC-0005..0007؛ روی DB اجرا نشد)
  - `virtual_meetings`: ستون‌های `provider` (پیش‌فرض برای ردیف‌های قدیمی: `ADOBE`)،
    `external_meeting_id` (مثلاً `lms-class-42`)، `last_started_at`، `record_video`
    (BIT، nullable → null یعنی `bbb.record-video-default`) (T7).
  - جدول `meeting_recordings`: `record_id`, `meeting_id`, `class_session_id`, `format`,
    `playback_url`, `video_url`, `duration_sec`, `size_bytes`, `published`, `started_at`,
    `created_at`.
  - جدول حضور موجود (`attendance_records`) از callback تحلیلی پر شود (`principal_id` برای
    BBB = `userID` ما).
- [x] **مدل اتاق:** یک meetingID ثابت به ازای هر کلاس (`lms-class-{classId}`)؛ هر بار اجرا یک
  `recordID` جدا می‌سازد. شناسه‌ی جلسه (`ClassSession`) در `meta_lms-session-id`.
- [x] **جریان استاد — `POST /{classId}/start`:** (تسک 15) فقط مدرس **همان کلاس** یا ADMIN (چک
  مالکیت از course-service). `create` idempotent با: `name`, `welcome` فارسی, `record=true`,
  `autoStartRecording=false`, `allowStartStopRecording=true`, `muteOnStart=true`,
  `guestPolicy`, `logoutURL` (صفحه‌ی کلاس در LMS), `meetingExpireWhenLastUserLeftInMinutes`,
  `meta_lms-class-id`, `meta_lms-session-id`, `meta_bbb-recording-ready-url`,
  `meta_endCallbackUrl`, `meta_analytics-callback-url`. خروجی: join URL با `role=MODERATOR`.
  - **اعلان ضبط (T8):** `notifyRecordingIsOn=true` + `notifyRecordingAppend` با متن فارسی
    (مثلاً «این جلسه ضبط می‌شود و ضبط آن در سامانه برای دانشجویان کلاس قابل مشاهده است.») →
    به هر کاربر هنگام شروع ضبط یک دیالوگ تأیید نمایش داده می‌شود.
  - **ویدئو برای هر کلاس (T7):** اگر `record_video` کلاس (یا پیش‌فرض) `false` است →
    `meta_bbb-disable-recording-formats=video` (فقط presentation ساخته می‌شود؛ ویدئو پردازش و
    منتشر نمی‌شود و callback آن هم نمی‌آید).
- [x] **`PATCH /{classId}/settings`** (فقط مدرس کلاس/ADMIN): `recordVideo` (T7) — روی اجرای
  **بعدی** کلاس اثر دارد (پارامتر create).
- [x] **جریان دانشجو — `GET /{classId}/join`:** چک ثبت‌نام در کلاس (course-service)؛ اگر
  `isMeetingRunning=false` → `409` با پیام «کلاس هنوز توسط استاد شروع نشده». در غیر این‌صورت
  join URL با `role=VIEWER`, `userID=<lmsUserId>`, `fullName` (از security-service), `redirect=true`,
  `userdata-bbb_override_default_locale`. join URL همیشه **on-demand** ساخته شود، ذخیره/لاگ نشود.
- [x] **`POST /{classId}/end`:** چک مالکیت (رفع باگ فعلی) + `end` در BBB.
- [x] **Callbackها** (عمومی از gateway، ولی هرکدام امضا را چک کند): (تسک 16؛ به جای `meta_endCallbackUrl`
  منسوخ از `meetingEndedURL` استفاده شد چون meta_* برای کاربران کلاس قابل دیدن است؛ توکن = HMAC per meeting)
  - `POST /api/v1/virtual-classes/callbacks/recording-ready` — پارامتر `signed_parameters`
    (JWT HS256 با shared secret) → `getRecordings` → ذخیره در `meeting_recordings` → event کافکا
    `RECORDING_READY`.
  - `POST /callbacks/analytics` — هدر `Authorization: Bearer <JWT HS512>` → حضور و غیاب
    (زمان ورود/خروج، مدت، talk time) → `attendance_records` → event `ATTENDANCE_RECORDED`.
  - `GET /callbacks/meeting-ended?token=...` — بدون امضا از سمت BBB → توکن خودمان در URL.
  - مسیرها به `RouteValidator.openApiEndpoints` در gateway اضافه شوند (بدون JWT).
  - BBB callback به IP خصوصی را بلاک می‌کند (`BaseUrlRedirectValidator`) → `callback-base-url`
    باید دامنه‌ی عمومی LMS باشد، یا `fetchUrlAllowedLocalHosts` ست شود.
- [x] **`GET /{classId}/recordings`:** (تسک 17) از `meeting_recordings` (و در صورت نیاز sync با
  `getRecordings`)؛ برگرداندن `playback_url` (پلیر presentation) و `video_url` (فایل ویدئو).
  هر فرمت جدا callback می‌دهد (T7) → ردیف با `presentation` زودتر آماده می‌شود، `video_url`
  بعداً پر می‌شود؛ وضعیت `PROCESSING` برای فرمتی که هنوز نیامده. حذف/عدم‌انتشار ضبط فقط برای
  مدرس کلاس.
- [x] **notification-service:** (تسک 17: `fullUrl` = `virtual-classroom.class-page-url`) `fullUrl` دیگر لینک مستقیم BBB نباشد (join URL per-user و
  امضاشده است) → لینک صفحه‌ی کلاس در فرانت LMS.
- [x] تست‌ها (۳۵ تست، همه پاس): `VirtualClassroomServiceImplTest` برای هر دو provider؛ تست callbackها با JWT
  معتبر/نامعتبر؛ تست مجوز (مدرس کلاس دیگر → 403)؛ تست اینکه create با `recordVideo=false`
  پارامتر `meta_bbb-disable-recording-formats=video` و همیشه `notifyRecordingIsOn=true` دارد.

**معیار پذیرش:** از Swagger gateway: start (استاد) → join (دانشجو) → ضبط → end → چند دقیقه
بعد ضبط در `/recordings` و حضور در `/attendance` دیده شود؛ همه‌ی سرویس‌ها بعد از تغییر config
سالم بالا بیایند (config-service بدون `ValidationFailedException`).

---

## فاز ۵ — فرانت LMS

- [x] hook های `useStartClass`, `useJoinClass`, `useClassRecordings`. (تسک 18: `hooks/useVirtualClass.ts`)
- [x] **پنل استاد:** (`/panel/teaching/classes/[classId]`) دکمه‌ی «شروع کلاس آنلاین» روی جلسه/کلاس → `POST /start` → باز کردن در
  تب جدید؛ دکمه‌ی «پایان کلاس»؛ نشانگر «در حال برگزاری».
- [x] **تنظیمات کلاس آنلاین برای استاد:** سوییچ «ساخت فایل ویدئویی از ضبط» (`recordVideo`،
  T7) با توضیح «فایل قابل دانلود؛ آماده شدنش بیشتر طول می‌کشد. پخش آنلاین ضبط همیشه فعال است».
- [x] **راهنمای اسلاید (T4):** کنار دکمه‌ی شروع کلاس یک نکته‌ی ثابت: «برای نمایش دقیق فونت و
  چیدمان فارسی، اسلایدها را PDF آپلود کنید.»
- [x] **پنل دانشجو:** (تسک 19) `live-session-banner.tsx` → «ورود به کلاس» واقعاً `GET /join` را صدا بزند؛
  حالت 409 → پیام «هنوز شروع نشده» و تلاش خودکار هر ۳۰ ثانیه.
- [x] صفحه‌ی «ضبط‌های کلاس»: (`/panel/classes/[classId]`) لیست با تاریخ شمسی، مدت، دکمه‌ی پخش (presentation) و دانلود
  ویدئو؛ اگر ویدئو هنوز پردازش می‌شود → «در حال آماده‌سازی فایل ویدئو»؛ اگر برای آن جلسه
  خاموش بوده → دکمه‌ی دانلود نمایش داده نشود (T7). برای استاد: حذف/مخفی‌کردن.
- [x] صفحه‌ی حضور و غیاب کلاس برای استاد (از `/attendance`).
- [x] `logoutURL` → صفحه‌ای در LMS (`/panel/classes/[classId]/left`) که بعد از خروج از کلاس نمایش داده می‌شود.

**معیار پذیرش:** سناریوی کامل استاد + ۲ دانشجو فقط از UI LMS، بدون دست‌کاری URL.

---

## فاز ۶ — مدیریت کلاس توسط استاد (چک‌لیست تست، همه built-in)

- [ ] استاد = MODERATOR، دانشجو = VIEWER (نقش فقط از LMS تعیین شود).
- [ ] قطع صدای همه / همه به جز ارائه‌دهنده؛ `muteOnStart`.
- [ ] Lock viewers: وبکم، میکروفون، **چت عمومی، چت خصوصی**، یادداشت، دیدن لیست کاربران.
- [ ] اخراج کاربر، دادن/گرفتن نقش ارائه‌دهنده و مدیر.
- [ ] اتاق انتظار (`guestPolicy=ASK_MODERATOR`) — اگر لازم است.
- [ ] شروع/توقف ضبط با دکمه (`allowStartStopRecording=true`, `autoStartRecording=false`).
- [ ] **اعلان ضبط (T8):** با شروع ضبط، دانشجو دیالوگ اعلان ضبط را با متن فارسی
  `notifyRecordingAppend` می‌بیند (هم دانشجویی که از قبل در کلاس است، هم کسی که بعد از شروع ضبط
  وارد می‌شود).
- [ ] **ویدئو خاموش (T7):** کلاسی با `recordVideo=false` → بعد از پایان فقط `presentation` در
  `published/` ساخته شود، نه `video`.
- [ ] آپلود اسلاید، وایت‌برد، اشتراک صفحه، ویدئوی خارجی، نظرسنجی، تایمر، breakout.
- [ ] چت: عمومی + خصوصی، پین پیام، پاک کردن چت، ذخیره‌ی چت؛ همه با UI فارسی.
- [ ] Learning Dashboard برای استاد.

---

## فاز ۷ — عملیات، امنیت، پایداری

- [x] Backup روزانه‌ی (تسک 22: `deploy/tools/backup.sh` + نمونه‌ی cron؛ اجرا روی سرور نشده) `BBB_RECORDINGS_DIR/published` (+ raw در صورت نیاز) به سرور/فضای دیگر.
- [x] مانیتورینگ (حداقلی: `deploy/tools/health-check.sh`؛ bbb-exporter فقط پیشنهاد در README): `bbb-exporter` (Prometheus) یا حداقل هشدار دیسک/CPU؛ health check روی API.
- [ ] امنیت: secret فقط در `.env` سرورها؛ SSH فقط با کلید؛ `ufw` فقط پورت‌های لازم؛ آپدیت
  امنیتی Ubuntu و BBB (`bbb-install.sh` دوباره → `apply-config.sh` خودکار اعمال می‌شود).
- [ ] تست بار: N کلاس هم‌زمان طبق D5 (مثلاً با `bigbluebutton-tests`)؛ مصرف CPU/پهنای‌باند
  ثبت شود.
- [ ] **اندازه‌گیری پردازش ضبط (T7):** (ابزار آماده: `deploy/tools/measure-recording.sh` + راهنما در README؛
  اندازه‌گیری واقعی منتظر سرور — تسک 20/22) برای یک کلاس ۹۰ دقیقه‌ای واقعی (وبکم استاد + اشتراک
  صفحه + اسلاید) زمان پردازش و حجم هر فرمت جدا ثبت شود (`bbb-record --watch`، لاگ‌های
  `/var/log/bigbluebutton/`). قاعده‌ی تصمیم:
  - اگر صف پردازش تا شروع کلاس‌های روز بعد خالی نمی‌شود، یا پردازش هم‌زمان با کلاس‌های زنده
    CPU را بالای ~۷۰٪ می‌برد → `bbb.record-video-default=false` (ویدئو فقط برای کلاس‌هایی
    که استاد روشن می‌کند) و/یا `BBB_RAP_WORKERS` تنظیم شود.
  - نتیجه‌ی اندازه‌گیری و تصمیم در همین فایل ثبت شود.
- [x] **اعلان ضبط (T8)** (تسک 22: بخش «ضبط کلاس‌های آنلاین» در `/terms`؛ نیاز به بازبینی حقوقی) در متن قوانین/حریم خصوصی LMS هم ذکر شود (جلسه‌ها ممکن است ضبط شوند
  و ضبط در دسترس اعضای همان کلاس است).
- [x] Runbook کوتاه در `lms-integration/deploy/README.md`: نصب، آپدیت، تغییر secret، جابه‌جایی دیسک،
  عیب‌یابی (`bbb-conf --check`, `bbb-record --watch`, لاگ‌های `/var/log/bigbluebutton`).
- [x] به‌روزرسانی `docs/DEPLOYMENT.md` و `docs/ARCHITECTURE.md` (Adobe → BBB).

---

## فاز ۸ — کلاس زنده همراه با فعالیت آموزشی

> اصل طراحی: **حضور یا روشن بودن صفحه به‌تنهایی یادگیری نیست.** گزارش کلاس فقط «شواهد» را
> کنار هم می‌گذارد (حضور، مشارکت، پاسخ به آزمون کوتاه، انجام تکلیف بعد از کلاس) و هیچ «نمره‌ی
> یادگیری» ترکیبی از حضور نمی‌سازد. دانشجویی که حاضر بوده ولی به هیچ فعالیت ارزیابی‌شده‌ای پاسخ
> نداده، در گزارش مشخص می‌شود.
>
> T2 همچنان برقرار است: BBB fork نمی‌شود؛ همه‌چیز با API رسمی (`create`.`groups`،
> `sendChatMessage`) و callback تحلیلی انجام می‌شود.
>
> سوییچ: `LIVE_CLASS_ACTIVITIES_ENABLED` (پیش‌فرض `false`) → `virtual-classroom.live-activities.enabled`.
> خاموش = APIهای جدید `404`، پارامتر `groups` به BBB فرستاده نمی‌شود، UI مخفی. داده‌ی مشارکت از
> callback تحلیلی در هر حال ذخیره می‌شود (هزینه ندارد، و با روشن شدن فوراً قابل نمایش است).

| # | قابلیت | پیاده‌سازی |
|---|---|---|
| ۸-۱ | حضور و مشارکت | callback تحلیلی: `engagement` هر نفر (`chats`, `talks`, `raisehand`, `emojis`, `poll_votes`, `talk_time`) در ستون‌های جدید `attendance_records`؛ `polls` در جدول `live_polls` (سؤال + تعداد رأی هر گزینه — BBB شناسه‌ی داخلی کاربر را حذف می‌کند، پس رأی هر نفر قابل نسبت‌دادن نیست، فقط تعداد رأی هر نفر). هر اجرای کلاس یک ردیف `meeting_runs` (runId = `internalMeetingID`، جلسه، زمان). |
| ۸-۲ | آزمون کوتاه هنگام تدریس | نظرسنجی سریع = Poll خود BBB (built-in). آزمون نمره‌دار = آزمون assessment-service: استاد از پنل یک آزمون درس را «اجرا در کلاس» می‌کند → `sendChatMessage` لینک آزمون را در چت عمومی می‌گذارد → ردیف `live_activities` → نتایج زنده از `quiz-taking/courses/{id}/results`. دانشجوی کلاس (نه فقط دانشجوی درس) اجازه‌ی شرکت دارد. |
| ۸-۳ | گروه‌بندی برای حل مسئله | جدول `breakout_groups` (نام، مسئله، اعضا) به ازای کلاس؛ ساخت تصادفی یا دستی. در `create` پارامتر `groups` (roster = `userID` همان شناسه‌ی LMS) → استاد در BBB «اتاق‌های گروهی» را باز می‌کند و اعضا از پیش چیده شده‌اند. چون `groups` فقط هنگام create اعمال می‌شود، تغییر گروه‌ها روی اجرای **بعدی** اثر دارد. دانشجو در LMS «گروه من و مسئله» را می‌بیند؛ استاد می‌تواند مسئله‌ها را در چت هم بفرستد. |
| ۸-۴ | ضبط ← فصل‌های دوره | جدول `recording_chapters` (recordId، زمان شروع، عنوان، `moduleId` فصل درس). پخش از همان ثانیه با `?t=` پلیر. صفحه‌ی فصل درس، بخش‌های ضبط مرتبط را (فقط برای اعضای همان کلاس) نشان می‌دهد. |
| ۸-۵ | تکلیف بعد از کلاس | استاد موضوعات تدریس‌شده را از topicهای بانک سؤال درس انتخاب می‌کند (پیشنهاد اولیه از عنوان فصل‌های ضبط) → assessment-service `POST /api/v1/quizzes/from-topics` آزمونی از نوع `ASSIGNMENT` با سؤال‌های تأییدشده‌ی همان موضوعات می‌سازد و منتشر می‌کند (مهلت = `availableTo`) → ردیف `live_activities` نوع `FOLLOW_UP`. نتیجه‌اش در گزارش کلاس می‌آید. |

- [x] ۸-۱ تا ۸-۵ backend (`virtual-classroom-service` بسته‌ی `live`، assessment-service endpoint موضوع‌محور، course-service بدون تغییر)
- [x] UI پنل استاد (`/panel/teaching/classes/[classId]`) و دانشجو (`/panel/classes/[classId]`)
- [ ] تست روی BBB واقعی: `groups` در BBB 4.0 + ورود دانشجو به اتاق گروه از پیش‌چیده؛ رسیدن `polls` و `engagement` در callback؛ پرش `?t=` در پلیر

---

## ترتیب پیشنهادی اجرا

1. فاز ۰ (تصمیم‌ها) → ۲. فاز ۱ و **هم‌زمان** فاز ۳-ترجمه و فاز ۴ (کد LMS روی یک BBB تستی) →
3. فاز ۲ (نصب واقعی) → ۴. فاز ۵ → ۵. فاز ۶ (تست پذیرش) → ۶. فاز ۷.

## مراجع

- مستند نصب داخل سورس: `bigbluebutton/docs/docs/administration/install.md`
- TURN: `bigbluebutton/docs/docs/administration/turn-server.md`؛ سوییچ‌های نصب:
  https://github.com/bigbluebutton/bbb-install/blob/v4.0.x-release/README.md
- ترجمه / Transifex: `bigbluebutton/docs/docs/development/localization.md`
- تبدیل اسلاید (mount فونت‌های host): `bigbluebutton/bbb-libreoffice/assets/convert-local.sh`
- سفارشی‌سازی (apply-config، ضبط، جابه‌جایی `/var/bigbluebutton`):
  `bigbluebutton/docs/docs/administration/customize.md`
- پارامترهای API: `bbb-common-web/src/main/java/org/bigbluebutton/api/ApiParams.java`
- callbackها: `record-and-playback/core/scripts/post_publish/post_publish_recording_ready_callback.rb`,
  `record-and-playback/core/scripts/post_events/post_events_analytics_callback.rb`
- Docker community: https://github.com/bigbluebutton/docker
