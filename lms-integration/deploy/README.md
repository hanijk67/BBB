# lms-integration/deploy — نصب BigBlueButton برای LMS

> نقشه‌ی کامل: [`../BBB_INTEGRATION_PLAN.md`](../BBB_INTEGRATION_PLAN.md). runbook عملیات در انتهای همین
> فایل (بخش «Runbook»)؛ سناریوهای تست پذیرش: [`ACCEPTANCE.md`](ACCEPTANCE.md).

BBB از پکیج رسمی (`bbb-install.sh`، برنچ `v4.0.x-release`، `-v noble-400`) روی Ubuntu 24.04 نصب
می‌شود؛ ما fork/build نمی‌کنیم (T1، T2). هر سفارشی‌سازی فقط یک فایل در `overrides/` + یک مرحله در
`apply-config.sh` است. **هیچ فایلی روی سرور دستی ادیت نشود.**

## ساختار

```
deploy/
├── .env.example          همه‌ی متغیرها (کپی به .env؛ .env commit نمی‌شود)
├── lib/env.sh            load و validate کردن .env (مشترک همه‌ی اسکریپت‌ها)
├── install-turn.sh       نصب سرور TURN جدا (روی سرور TURN)
├── install.sh            نصب/آپدیت BBB + mount دیسک ضبط + نصب apply-config (روی سرور BBB)
├── apply-config.sh       → /etc/bigbluebutton/bbb-conf/apply-config.sh؛ بعد از هر restart/آپدیت
├── TRANSIFEX.md          راهنمای ارسال ترجمه به Transifex خود BBB
├── ACCEPTANCE.md         سناریوهای تست پذیرش فاز ۳، ۵، ۶ + جدول نتیجه
├── overrides/
│   ├── recording.yml     فرمت‌های ضبط presentation + video (T7)
│   ├── fa_IR.json        ترجمه‌ی کامل فارسی کلاینت
│   ├── assets/           custom.css + fonts/*.woff2 (self-host روی nginx خود BBB؛ T5)
│   └── fonts/            *.ttf + 99-lms-fa.conf برای تبدیل اسلاید در LibreOffice (T4)
└── tools/
    ├── preflight.sh      چک‌های فاز ۱ (PASS/FAIL)
    ├── check-turn.sh     تست پورت‌ها و گواهی TURN از بیرون + راهنمای تست relay
    ├── locale-diff.py    diff کلیدهای en.json / fa_IR.json
    ├── glossary-fa.md    واژه‌نامه‌ی ترجمه
    ├── test-slides/      روش تست اسلاید فارسی
    ├── backup.sh         بکاپ rsync ضبط‌های منتشرشده (cron)
    ├── health-check.sh   هشدار دیسک/CPU/API/صف ضبط (cron)
    ├── measure-recording.sh  زمان و حجم پردازش هر فرمت ضبط (T7)
    └── out/              خروجی ابزارها (در git نیست)
```

روی سرور BBB، `install.sh` این‌ها را در `/etc/bigbluebutton/lms/` کپی می‌کند (`.env` با مجوز 600،
`lib/`، `overrides/`) و `apply-config.sh` فقط از همان‌جا می‌خواند.

## ترتیب اجرا

1. **TURN**: پیش‌فرض داخلی است (`BBB_TURN_HOST` خالی) و قدمی ندارد. فقط برای TURN جدا:
   `sudo ./install-turn.sh` روی سرور TURN → از بیرون `tools/check-turn.sh`
2. **BBB**: `sudo tools/preflight.sh` → `sudo ./install.sh`
3. **apply-config**: خودکار با هر `bbb-conf --restart`؛ دستی:
   `sudo /etc/bigbluebutton/bbb-conf/apply-config.sh && sudo bbb-conf --restart`

بعد از تغییر `.env` یا `overrides/` روی ریپو: دوباره `sudo ./install.sh` (idempotent؛ مراحلی که
انجام شده‌اند رد می‌شوند).

## پیش‌نیازها (فاز ۱)

- [ ] سرور BBB: Ubuntu 24.04 تمیز (بدون apache/nginx/panel)، کرنل 6.x، x86_64
- [ ] سرور BBB: production حداقل 8 هسته‌ی dedicated، 16GB RAM + swap (تست: 4 هسته / 8GB)
- [ ] سرور BBB: دیسک جدا برای ضبط، mount شده روی مسیر `BBB_RECORDINGS_DIR` (مستند رسمی: 500GB)
- [ ] سرور BBB: IP عمومی ثابت؛ فایروال بیرونی TCP 80، 443، UDP 16384-32768 و (TURN داخلی) TCP/UDP 3478 باز
- [ ] DNS: `class.glmp.ir → <BBB_IP>` (`dig +short class.glmp.ir`)
- [ ] شبکه: دسترسی سرور BBB به `ubuntu.bigbluebutton.org`، GitHub raw، Let's Encrypt و
      Docker Hub (یا `DOCKER_REGISTRY_MIRROR`) — `tools/preflight.sh` تست می‌کند
- [ ] secret: `BBB_SHARED_SECRET` با `openssl rand -hex 32`

فقط برای TURN جدا (`BBB_TURN_HOST` پر):

- [ ] سرور TURN: VPS کوچک (1–2 هسته، 1–2GB)، Ubuntu 24.04 تمیز، IP عمومی جدا
- [ ] DNS: `turn.glmp.ir → <TURN_IP>`
- [ ] فایروال بیرونی TURN: TCP 22، 80؛ TCP/UDP 3478 و 443؛ UDP 32769-65535
- [ ] `BBB_TURN_SECRET` ۸–۱۶ کاراکتر حرف/عدد (مثلاً `openssl rand -hex 8`) — روی هر دو سرور یکی

## TURN (T3)

دانشجوهایی که UDP ندارند (اینترنت موبایل، شبکه‌ی محدود) فقط از طریق TURN روی TCP/TLS 443 صدا و
تصویر می‌گیرند. دو حالت با `BBB_TURN_HOST`:

### TURN داخلی (پیش‌فرض، `BBB_TURN_HOST` خالی)

`install.sh` به `bbb-install.sh` گزینه‌ی `-c` نمی‌دهد → bbb-install خودش `bbb-coturn` را روی همین سرور
نصب می‌کند (secret تصادفی در `/etc/turnserver.conf`) و `haproxy` را جلوی 443 می‌گذارد: اتصال با ALPN
`stun.turn` به coturn (3478) و بقیه به nginx می‌رود. bbb-web آدرس `turns:class.glmp.ir:443?transport=tcp` و
`turn:class.glmp.ir:3478` را به مرورگر می‌دهد. `enableUFWRules` (داخل apply-config) با دیدن haproxy پورت
3478 را در ufw باز می‌کند. دامنه‌ی دوم و سرور دوم لازم نیست. اگر قبلاً TURN جدا بوده،
`/etc/bigbluebutton/turn-stun-servers.xml` با پسوند `.bak` کنار گذاشته می‌شود. تست: `BBB_TURN_HOST=class.glmp.ir tools/check-turn.sh`
(چک 443/TLS و 3478).

### TURN جدا (`BBB_TURN_HOST=turn.glmp.ir`)

برای بار زیاد: relay روی سرور دیگری می‌رود. چون 443 روی سرور TURN باید آزاد باشد، IP جدا لازم است.

```bash
# روی سرور TURN (به‌عنوان root)
cp .env.example .env && nano .env      # BBB_TURN_HOST, BBB_TURN_SECRET, BBB_LETSENCRYPT_EMAIL
sudo ./install-turn.sh
```

`install-turn.sh` این کارها را می‌کند (همه قابل اجرای مجدد):

1. چک Ubuntu 24.04، رکورد A `BBB_TURN_HOST` = IP همین سرور، آزاد بودن 443، طول secret.
2. `ufw`: 22/tcp، 80/tcp (فقط چالش Let's Encrypt)، 3478 و 443 tcp/udp، 32769-65535/udp.
3. `bbb-install.sh -c "$BBB_TURN_HOST:$BBB_TURN_SECRET" -e "$BBB_LETSENCRYPT_EMAIL"` (بدون `-v`)
   برای نصب پکیج `bbb-coturn` و سرویس.
4. **تکمیل کانفیگ** طبق `docs/docs/administration/turn-server.md`، چون `bbb-install.sh` برنچ
   v4.0.x-release در این حالت secret ورودی را نادیده می‌گیرد (secret تصادفی می‌سازد)، TLS روی 443
   را تنظیم نمی‌کند و relay را فقط به IP خود سرور TURN مجاز می‌کند: گواهی Let's Encrypt
   (`certbot --standalone`) + renewal-hook برای کاربر `turnserver`، `dhp.pem`،
   `/etc/turnserver.conf` با `tls-listening-port=443` و `static-auth-secret=$BBB_TURN_SECRET`، و
   systemd override با `CAP_NET_BIND_SERVICE`.

تست از بیرون (لپ‌تاپ یا سرور BBB):

```bash
BBB_TURN_HOST=turn.glmp.ir tools/check-turn.sh
```

بعد از نصب BBB با `-c` (داخل `install.sh`)، bbb-web آدرس `turns:turn.glmp.ir:443?transport=tcp` و
`turn:turn.glmp.ir:3478` را از `/etc/bigbluebutton/turn-stun-servers.xml` به مرورگر می‌دهد. تست
relay در `about:webrtc` / `chrome://webrtc-internals` — راهنما در خروجی `check-turn.sh`.

## BBB

```bash
# روی سرور BBB (به‌عنوان root)
cp .env.example .env && nano .env
sudo tools/preflight.sh         # همه PASS (WARN برای سرور تستی قابل قبول است)
sudo ./install.sh
```

مراحل `install.sh`: preflight → registry mirror (merge در `/etc/docker/daemon.json`) →
`bbb-install.sh -v $BBB_VERSION -s $BBB_DOMAIN -e ...` (+ `-c $BBB_TURN_HOST:$BBB_TURN_SECRET` فقط برای TURN جدا؛ بدون `-g`) →
bind mount `/var/bigbluebutton` روی `BBB_RECORDINGS_DIR` (با چک فضای دیسک و خط fstab بدون تکرار) →
نصب `apply-config.sh` → `bbb-conf --restart` و `bbb-conf --check`.

`apply-config.sh` (جزئیات در خود فایل): `bbb-web.properties` (secret، مهمان، ضبط، اعلان ضبط،
`fetchUrlAllowedLocalHosts`)، `bbb-html5.yml` (`overrideLocale`، `fallbackLocale`، `customStyleUrl`)،
ضبط (`recording.yml`، `bbb-playback-video`، mp4 در `presentation.yml`، `COUNT` worker)، کپی
`fa_IR.json`، فونت‌ها + `fc-cache`، assetها در `/var/www/bigbluebutton-default/assets/lms-assets/`،
نگهداری raw (`published_days` در `/etc/default/bigbluebutton-cron-config`). قوانین فایروال
پیش‌فرض BBB (`enableUFWRules`) هم حفظ شده‌اند.

---

# Runbook

همه‌ی دستورها روی سرور BBB و با root، مگر خلاف آن گفته شده. ریپوی `lms-integration` روی سرور در
`/opt/lms-integration` فرض شده (`git clone` یا `rsync` از ماشین شما). **هیچ فایل سیستمی را دستی ادیت
نکنید** (T2): تغییر = فایل در `overrides/` یا مقدار در `.env` + دوباره `./install.sh`.

## نصب اول

1. (فقط TURN جدا) سرور TURN: `cd /opt/lms-integration/deploy && cp .env.example .env && nano .env` → `sudo ./install-turn.sh`
   و از لپ‌تاپ `BBB_TURN_HOST=turn.glmp.ir tools/check-turn.sh` (همه PASS)
2. سرور BBB: `.env` (TURN داخلی: `BBB_TURN_HOST` خالی؛ TURN جدا: همان `BBB_TURN_SECRET`) →
   `sudo tools/preflight.sh` → `sudo ./install.sh`
3. (TURN داخلی) از لپ‌تاپ: `BBB_TURN_HOST=class.glmp.ir tools/check-turn.sh`
4. چک‌های معیار پذیرش فاز ۲:
   ```bash
   curl -s https://class.glmp.ir/bigbluebutton/api | grep SUCCESS
   bbb-conf --check
   df -h /var/bigbluebutton          # باید دیسک BBB_RECORDINGS_DIR را نشان دهد
   findmnt /var/bigbluebutton
   ```
5. cronها (یک بار):
   ```bash
   cat > /etc/cron.d/lms-bbb <<'CRON'
   30 2 * * * root /etc/bigbluebutton/lms/tools/backup.sh >/dev/null 2>&1
   */5 * * * * root /etc/bigbluebutton/lms/tools/health-check.sh >/dev/null 2>&1
   CRON
   ```
6. سمت LMS: در `.env` سرور LMS مقادیر `BBB_ENABLED=true`، `BBB_API_URL`، `BBB_SHARED_SECRET` (همان مقدار)،
   `BBB_CALLBACK_BASE_URL` (آدرس عمومی gateway)، `BBB_CALLBACK_TOKEN`، `LMS_FRONTEND_URL` → ری‌استارت
   virtual-classroom-service (جزئیات: `LMS_MICRO/docs/DEPLOYMENT.md` بخش «Live classes»).

## آپدیت BBB

```bash
cd /opt/lms-integration && git pull           # اگر overrides/ عوض شده
sudo deploy/install.sh                        # bbb-install.sh همان -v → آخرین نسخه‌ی 4.0.x
python3 -I deploy/tools/locale-diff.py --check   # کلید ترجمه‌ی جدید؟ (روی ماشین توسعه با سورس جدید)
```
`install.sh` دوباره `bbb-install.sh` را اجرا می‌کند؛ `bbb-conf` در انتها `apply-config.sh` را صدا می‌زند، پس
ترجمه، فونت، CSS، ضبط و secret دوباره اعمال می‌شوند. اگر `locale-diff.py` کلید کم گزارش داد: ترجمه در
`overrides/fa_IR.json` + Transifex (`TRANSIFEX.md`) → دوباره `install.sh`.

## تغییر secret

- **API (`BBB_SHARED_SECRET`)**: مقدار جدید (`openssl rand -hex 32`) در `.env` سرور BBB و `.env` سرور LMS؛
  `sudo ./install.sh` روی BBB (یا فقط `sudo /etc/bigbluebutton/bbb-conf/apply-config.sh && sudo bbb-conf --restart`
  بعد از کپی `.env` به `/etc/bigbluebutton/lms/.env`)، بعد ری‌استارت virtual-classroom-service. بین این دو
  قدم کلاس جدید ساخته نمی‌شود (checksumError) — در ساعت بدون کلاس انجام دهید. callbackهای ضبطِ در صف با
  secret جدید امضا می‌شوند، پس مشکلی ندارند.
- **TURN (`BBB_TURN_SECRET`)**: فقط برای TURN جدا — مقدار جدید در `.env` هر دو سرور → `sudo ./install-turn.sh`
  روی TURN و `sudo ./install.sh` روی BBB. TURN داخلی secret را خود bbb-install در `/etc/turnserver.conf` نگه می‌دارد.
- **`BBB_CALLBACK_TOKEN`** (فقط LMS): تغییرش لینک meeting-ended جلسه‌های در حال اجرا را باطل می‌کند →
  وقتی کلاسی در حال برگزاری نیست.

## جابه‌جایی دیسک ضبط

دیسک جدید را mount کنید (مثلاً `/data2`)، بعد:
```bash
bbb-conf --stop
rsync -aH --info=progress2 /var/bigbluebutton/ /data2/bigbluebutton/
umount /var/bigbluebutton
sed -i 's#^/data/bigbluebutton /var/bigbluebutton #/data2/bigbluebutton /var/bigbluebutton #' /etc/fstab
mount /var/bigbluebutton && df -h /var/bigbluebutton
bbb-conf --start
```
و `BBB_RECORDINGS_DIR=/data2/bigbluebutton` در `.env` (تا `install.sh` بعدی همان را ببیند). دیسک قبلی را
تا تأیید پخش چند ضبط قدیمی نگه دارید.

## بکاپ و بازگردانی

- `tools/backup.sh`: `published/` و `unpublished/` (و `recording/raw` اگر `BBB_BACKUP_INCLUDE_RAW=true`) به
  `BBB_BACKUP_DEST` با rsync، بدون `--delete`. لاگ: `journalctl -t bbb-backup`.
- بازگردانی روی سرور جدید (مستند customize.md «Transfer published recordings»):
  ```bash
  rsync -a <backup>/published/ /var/bigbluebutton/published/
  rsync -a <backup>/unpublished/ /var/bigbluebutton/unpublished/
  chown -R bigbluebutton:bigbluebutton /var/bigbluebutton/published /var/bigbluebutton/unpublished
  ```

## مانیتورینگ

- حداقل: `tools/health-check.sh` (cron هر ۵ دقیقه) — دیسک ≥ `BBB_ALERT_DISK_PCT`، load به ازای هر هسته،
  API، سرویس‌ها، صف ضبط؛ هشدار در syslog (`journalctl -t bbb-health`) و `BBB_ALERT_WEBHOOK`.
- پیشنهاد کامل‌تر: [bbb-exporter](https://github.com/greenstatic/bigbluebutton-exporter) + Prometheus +
  Grafana (تعداد کلاس/کاربر/وبکم زنده، زمان پاسخ API، صف ضبط) و node_exporter برای CPU/دیسک/شبکه. نصب آن
  کار جداگانه است و هنوز انجام نشده؛ قبل از نصب، نسخه‌ی سازگار با BBB 4.0 را بررسی کنید.

## اندازه‌گیری پردازش ضبط (T7)

برای یک کلاس واقعی ~۹۰ دقیقه (وبکم استاد + اشتراک صفحه + اسلاید، ضبط از اول تا آخر):
1. بعد از پایان کلاس: `bbb-record --watch` (پیشرفت) و `tail -f /var/log/bigbluebutton/bbb-rap-worker.log`.
2. وقتی هر دو فرمت آماده شدند: `sudo /etc/bigbluebutton/lms/tools/measure-recording.sh <recordID>` → CSV
   زمان پردازش (دقیقه) و حجم هر فرمت.
3. در همان بازه `uptime` / `top` — آیا پردازش هم‌زمان با کلاس زنده CPU را بالای ~۷۰٪ می‌برد؟
4. نتیجه را در `BBB_INTEGRATION_PLAN.md` فاز ۷ ثبت کنید. قاعده: اگر صف تا شروع کلاس‌های روز بعد خالی
   نمی‌شود یا CPU بالای ۷۰٪ می‌رود → `BBB_RECORD_VIDEO_DEFAULT=false` در `.env` LMS (ویدئو فقط برای
   کلاس‌هایی که استاد روشن می‌کند) و/یا `BBB_RAP_WORKERS` (تا وقتی KeepEvents خاموش است). کلید config
   `bbb.record-video-default` از env خوانده می‌شود؛ اگر خواستید مقدار پیش‌فرض خود ردیف عوض شود، فقط با
   changeset جدید در config-service (قانون CLAUDE.md).

## عیب‌یابی

| علامت | بررسی |
|---|---|
| هر چیزی | `bbb-conf --check`، `bbb-conf --status` |
| کلاس ساخته نمی‌شود (LMS 502) | لاگ virtual-classroom-service: `checksumError` → secret دو طرف یکی نیست؛ `curl https://class.glmp.ir/bigbluebutton/api` |
| دانشجو «کلاس شروع نشده» می‌بیند ولی استاد داخل است | `getMeetingInfo` با API-Mate؛ meetingID باید `lms-class-<classId>` باشد |
| صدا/تصویر برای بعضی کاربران وصل نمی‌شود | `tools/check-turn.sh`؛ `about:webrtc` کاندید relay؛ `journalctl -u coturn` روی TURN |
| ضبط در LMS «در حال آماده‌سازی» می‌ماند | `bbb-record --watch`؛ `/var/log/bigbluebutton/post_publish.log` (callback recording-ready)؛ آیا `BBB_CALLBACK_BASE_URL` از سرور BBB قابل دسترسی است؟ IP خصوصی → `BBB_ALLOWED_CALLBACK_HOSTS` |
| حضور و غیاب خالی است | `/var/log/bigbluebutton/post_events_analytics_callback.log` |
| UI انگلیسی یا فونت پیش‌فرض | `ls -l /usr/share/bigbluebutton/html5-client/locales/fa_IR.json`؛ `yq-go e '.public.app' /etc/bigbluebutton/bbb-html5.yml`؛ `curl -I https://class.glmp.ir/lms-assets/custom.css` |
| اسلاید فارسی مربع نشان می‌دهد | `fc-match "B Nazanin"` → باید Vazirmatn باشد؛ `tools/test-slides/README.md` |
| دیسک پر | `du -sh /var/bigbluebutton/*`؛ `published_days` در `/etc/default/bigbluebutton-cron-config` |
| لاگ‌ها | `/var/log/bigbluebutton/`، `journalctl -u bbb-web -u bbb-html5 -u bbb-rap-resque-worker` |
