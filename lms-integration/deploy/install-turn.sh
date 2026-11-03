#!/usr/bin/env bash
# نصب سرور TURN جدا (coturn) روی Ubuntu 24.04 تمیز — T3، فاز ۱-ب.
# روی سرور TURN اجرا شود (نه سرور BBB):  sudo ./install-turn.sh [path/to/.env]
#
# چرا بعد از bbb-install.sh خودمان turnserver.conf را می‌نویسیم:
# bbb-install.sh (برنچ v4.0.x-release) در حالت «-c بدون -v» فقط پکیج bbb-coturn و سرویس را
# نصب می‌کند ولی (۱) secret ورودی را نادیده می‌گیرد و secret تصادفی می‌سازد، (۲) TLS روی 443
# و گواهی را تنظیم نمی‌کند، (۳) relay را فقط به IP خود همین سرور مجاز می‌کند. پس کانفیگ را طبق
# docs/docs/administration/turn-server.md کامل می‌کنیم. همه‌ی مراحل قابل اجرای مجدد هستند.
set -euo pipefail

DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/env.sh
. "$DEPLOY_DIR/lib/env.sh"

require_root
load_env "${1:-}"
require_vars BBB_TURN_HOST BBB_TURN_SECRET BBB_LETSENCRYPT_EMAIL
validate_turn_secret

# --- ۱) سیستم‌عامل ---
# shellcheck disable=SC1091
. /etc/os-release
[[ "${ID:-}" == "ubuntu" && "${VERSION_ID:-}" == "24.04" ]] \
  || die "سرور TURN باید Ubuntu 24.04 باشد (الان: ${PRETTY_NAME:-نامشخص})"
ok "سیستم‌عامل: $PRETTY_NAME"

# --- ۲) DNS ---
TURN_IP="${BBB_TURN_PUBLIC_IP:-$(public_ipv4)}"
[[ -n "$TURN_IP" ]] || die "IP عمومی سرور تشخیص داده نشد؛ BBB_TURN_PUBLIC_IP را در .env ست کنید"
if resolve_a "$BBB_TURN_HOST" | grep -qx "$TURN_IP"; then
  ok "DNS: $BBB_TURN_HOST → $TURN_IP"
else
  die "رکورد A دامنه‌ی $BBB_TURN_HOST به $TURN_IP اشاره نمی‌کند (الان: $(resolve_a "$BBB_TURN_HOST" | tr '\n' ' '))"
fi

# --- ۳) پورت 443 باید آزاد باشد (مگر اینکه خود coturn از اجرای قبلی روی آن است) ---
listener_443="$(ss -Hltnp 'sport = :443' || true)"
if [[ -z "$listener_443" ]]; then
  ok "پورت 443 آزاد است"
elif grep -q turnserver <<<"$listener_443"; then
  ok "پورت 443 در اختیار coturn است (اجرای مجدد)"
else
  die "پورت 443 توسط برنامه‌ی دیگری اشغال است: $(awk '{print $NF}' <<<"$listener_443" | head -1)"
fi

# --- ۴) فایروال ---
log "تنظیم ufw: 22، 80 (فقط برای گواهی)، 3478 و 443 (tcp/udp)، 32769-65535/udp"
command -v ufw >/dev/null 2>&1 || apt-get install -y ufw
ufw allow 22/tcp
ufw allow 80/tcp          # چالش HTTP-01 برای certbot --standalone (صدور و تمدید)
ufw allow 3478/tcp
ufw allow 3478/udp
ufw allow 443/tcp
ufw allow 443/udp
ufw allow 32769:65535/udp
ufw --force enable
ok "ufw فعال شد"

# --- ۵) نصب coturn با اسکریپت رسمی (بدون -v) ---
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
fetch_bbb_install "$WORK_DIR/bbb-install.sh"
log "اجرای bbb-install.sh -c <host>:<secret> -e <email>"
"$WORK_DIR/bbb-install.sh" -c "$BBB_TURN_HOST:$BBB_TURN_SECRET" -e "$BBB_LETSENCRYPT_EMAIL"
command -v turnserver >/dev/null 2>&1 || die "turnserver بعد از bbb-install نصب نشده است"
ok "bbb-coturn نصب شد"

# --- ۶) گواهی Let's Encrypt برای TLS روی 443 ---
LE_DIR="/etc/letsencrypt/live/$BBB_TURN_HOST"
if [[ -f "$LE_DIR/fullchain.pem" ]]; then
  ok "گواهی موجود است: $LE_DIR"
else
  log "صدور گواهی برای $BBB_TURN_HOST (certbot --standalone)"
  certbot certonly --standalone --non-interactive --agree-tos --preferred-challenges http \
    -m "$BBB_LETSENCRYPT_EMAIL" -d "$BBB_TURN_HOST"
fi

mkdir -p /etc/turnserver /etc/letsencrypt/renewal-hooks/deploy
cat > /etc/letsencrypt/renewal-hooks/deploy/coturn <<HOOK
#!/bin/bash -e
# کپی گواهی برای کاربر turnserver (turn-server.md) — تولیدشده توسط install-turn.sh
for certfile in fullchain.pem privkey.pem ; do
	cp -L /etc/letsencrypt/live/$BBB_TURN_HOST/"\${certfile}" /etc/turnserver/"\${certfile}".new
	chown turnserver:turnserver /etc/turnserver/"\${certfile}".new
	mv /etc/turnserver/"\${certfile}".new /etc/turnserver/"\${certfile}"
done
systemctl kill -sUSR2 coturn.service || true
HOOK
chmod 0755 /etc/letsencrypt/renewal-hooks/deploy/coturn
/etc/letsencrypt/renewal-hooks/deploy/coturn
ok "گواهی در /etc/turnserver کپی شد (renewal-hook نصب شد)"

if [[ ! -s /etc/turnserver/dhp.pem ]]; then
  log "ساخت dhp.pem"
  openssl dhparam -dsaparam -out /etc/turnserver/dhp.pem 2048
fi

# --- ۷) /etc/turnserver.conf طبق turn-server.md ---
log "نوشتن /etc/turnserver.conf"
TMP_CONF="$(mktemp)"
cat > "$TMP_CONF" <<CONF
# تولیدشده توسط lms-integration/deploy/install-turn.sh — دستی ادیت نکنید (T2)
listening-port=3478
tls-listening-port=443

listening-ip=$TURN_IP
relay-ip=$TURN_IP

min-port=32769
max-port=65535
verbose

fingerprint
lt-cred-mech
use-auth-secret
static-auth-secret=$BBB_TURN_SECRET
realm=$BBB_TURN_HOST

cert=/etc/turnserver/fullchain.pem
pkey=/etc/turnserver/privkey.pem
cipher-list="ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384"
dh-file=/etc/turnserver/dhp.pem

keep-address-family
no-cli
no-tlsv1
no-tlsv1_1

no-loopback-peers
no-multicast-peers
denied-peer-ip=10.0.0.0-10.255.255.255
denied-peer-ip=172.16.0.0-172.31.255.255
denied-peer-ip=192.168.0.0-192.168.255.255
denied-peer-ip=100.64.0.0-100.127.255.255
denied-peer-ip=169.254.0.0-169.254.255.255
denied-peer-ip=192.0.0.0-192.0.0.255
denied-peer-ip=192.0.2.0-192.0.2.255
denied-peer-ip=198.18.0.0-198.19.255.255
denied-peer-ip=198.51.100.0-198.51.100.255
denied-peer-ip=203.0.113.0-203.0.113.255
denied-peer-ip=fc00::-fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff
denied-peer-ip=fe80::-febf:ffff:ffff:ffff:ffff:ffff:ffff:ffff
denied-peer-ip=::ffff:0:0-::ffff:ffff:ffff
denied-peer-ip=64:ff9b::-64:ff9b::ffff:ffff
denied-peer-ip=64:ff9b:1::-64:ff9b:1:ffff:ffff:ffff:ffff:ffff
denied-peer-ip=2001::-2001:1ff:ffff:ffff:ffff:ffff:ffff:ffff
denied-peer-ip=2001:db8::-2001:db8:ffff:ffff:ffff:ffff:ffff:ffff
denied-peer-ip=2002::-2002:ffff:ffff:ffff:ffff:ffff:ffff:ffff
CONF
install -o root -g turnserver -m 640 "$TMP_CONF" /etc/turnserver.conf
rm -f "$TMP_CONF"

# --- ۸) اجازه‌ی bind روی 443 (override نصب‌شده توسط bbb-install این خط را کامنت دارد) ---
mkdir -p /etc/systemd/system/coturn.service.d
cat > /etc/systemd/system/coturn.service.d/override.conf <<'UNIT'
[Service]
LimitNOFILE=1048576
AmbientCapabilities=CAP_NET_BIND_SERVICE
ExecStart=
ExecStart=/usr/bin/turnserver -c /etc/turnserver.conf --pidfile= --no-stdout-log --simple-log --log-file /var/log/turnserver/turnserver.log
Restart=always
UNIT
mkdir -p /var/log/turnserver
chown turnserver:turnserver /var/log/turnserver
systemctl daemon-reload
systemctl enable coturn
systemctl restart coturn

# --- ۹) بررسی نهایی ---
sleep 2
systemctl is-active --quiet coturn || die "coturn بالا نیامد: journalctl -u coturn -n 50"
ss -Hltnp 'sport = :443' | grep -q turnserver || die "coturn روی 443/tcp گوش نمی‌دهد"
ss -Hltnp 'sport = :3478' | grep -q turnserver || die "coturn روی 3478/tcp گوش نمی‌دهد"
ok "coturn روی 3478 و 443 (TLS) فعال است"
log "قدم بعد: از یک سیستم بیرونی tools/check-turn.sh را اجرا کنید؛ سپس install.sh روی سرور BBB"
