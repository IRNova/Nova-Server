<div align="center">

<img src="https://raw.githubusercontent.com/iiviirv/irnova-site/main/brand/nova-logo-badge-round.png" width="70" alt="Nova">

<div align="right">
  <a href="README.md">🇬🇧 English</a>
</div>

# Nova Server

**سرور پروکسی اختصاصی و مقاوم در برابر فیلترینگ شما، همراه با یک پنل مدیریت کامل، روی هر VPS.**

VLESS · VMess · Trojan · Shadowsocks · Reality · Hysteria2 · WireGuard، همراه با یک پنل مدرن
سه‌زبانه (English · فارسی · Русский)، حساب‌های چندکاربره، ناوگان چندنودی، تونل‌های پل ایران،
SSL یک‌کلیکی، ربات تلگرام با Mini App و احراز هویت دومرحله‌ای.

[![License](https://img.shields.io/badge/license-Proprietary-8b5cf6?style=for-the-badge)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-blueviolet?style=for-the-badge)](https://github.com/IRNova/Nova-Server)
[![Stars](https://img.shields.io/github/stars/IRNova/Nova-Server?style=for-the-badge&color=0ea5e9)](https://github.com/IRNova/Nova-Server)

</div>

---

## 🌐 پیوندها

<div align="center">

[![Website](https://img.shields.io/badge/🌐%20Website-novaproxy.online-0ea5e9?style=for-the-badge)](https://novaproxy.online/)
[![Telegram Channel](https://img.shields.io/badge/✈️%20Telegram%20Channel-@irnova__proxy-0ea5e9?style=for-the-badge&logo=telegram)](https://t.me/irnova_proxy)
[![Telegram Group](https://img.shields.io/badge/👥%20Telegram%20Group-@irnovaproxy__group-0ea5e9?style=for-the-badge&logo=telegram)](https://t.me/irnovaproxy_group)
[![YouTube](https://img.shields.io/badge/▶️%20YouTube-@novaproxyir-ff0000?style=for-the-badge&logo=youtube)](https://www.youtube.com/@novaproxyir)
[![X (Twitter)](https://img.shields.io/badge/𝕏%20X-@irNovaProxy-000000?style=for-the-badge&logo=x)](https://x.com/irNovaProxy)
[![Instagram](https://img.shields.io/badge/📸%20Instagram-@irnova__proxy-E4405F?style=for-the-badge&logo=instagram)](https://www.instagram.com/irnova_proxy)

</div>

---

## 📖 Nova Server چیست؟

Nova Server یک VPS ساده لینوکسی را به یک نود پروکسی خصوصی و مقاوم در برابر فیلترینگ همراه با یک **پنل مدیریت کامل** تبدیل می‌کند. این ابزار `Xray-core`، `sing-box` (برای Hysteria2) و `AmneziaWG` را پشت یک پورت اجرا می‌کند و همه را با یک ایجنت خودمیزبان مدیریت می‌کند. جایی که Nova Proxy روی لایه رایگان کلادفلر اجرا می‌شود، Nova Server **نسخه خودمیزبان و قدرتمندتر** است: یک هسته پروکسی واقعی با هر آنچه یک اپراتور جدی نیاز دارد.

**چه چیزی Nova Server را متمایز می‌کند:**
- 🧩 **همه پروتکل‌های مهم** — VLESS، VMess، Trojan، Shadowsocks، Reality، Hysteria2 و WireGuard بومی
- 🇮🇷 **تونل‌های پل ایران** — قرار دادن یک سرور با آی‌پی تمیز داخل ایران جلوی خروج خارجی (Backhaul، BackPack، rathole، wstunnel)
- 🔐 **SSL یک‌کلیکی** — Let's Encrypt یا Cloudflare کاملاً خودکار (DNS خودکار + وایلدکارت)، بدون درگیری دستی با پورت ۸۰
- 👥 **کنترل کامل هر کاربر** — سقف حجم، انقضا، محدودیت دستگاه، بازنشانی حجم و دسترسی پروتکل هر کاربر
- 🛰️ **ناوگان چندنودی** — مدیریت چندین سرور از یک پنل
- 🤖 **ربات تلگرام + Mini App** — اجرای کل پنل داخل تلگرام
- 🛡️ **خروج ضد فیلترینگ** — WARP (با لایسنس WARP+ خودتان)، Tor و Psiphon، به‌صورت داخلی
- ⚙️ **خودکارسازی** — پشتیبان‌گیری، هشدارهای سلامت، به‌روزرسانی خودکار، تازه‌سازی آی‌پی تمیز و راه‌انداز اولین اجرا
- 🌍 **پنل سه‌زبانه** — انگلیسی، فارسی (راست‌به‌چپ) و روسی، همراه با راهنمای کامل داخل پنل

---

## ⚡ نصب سریع

روی یک سرور تازه اوبونتو ۲۰.۰۴ به بالا یا دبیان ۱۱ به بالا (x86_64 یا arm64) این دستور را اجرا کنید:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

نصب‌کننده هسته‌های پروکسی، پنل و بک‌اند‌های تونل را راه‌اندازی می‌کند و آدرس پنل را نمایش می‌دهد. پنل را باز کنید، یک رمز مدیریت بگذارید و با «راه‌انداز خودکار» یک دامنه، یک پروتکل پیشنهادی و اولین کاربر خود را بسازید.

رمز را فراموش کرده‌اید؟ از روی سرور بازنشانی کنید:

```bash
nova-passwd 'YourNewPassword' --clear-2fa
```

---

## 🧩 امکانات

| بخش | چه چیزی دریافت می‌کنید |
|------|--------------|
| **پروتکل‌ها** | VLESS، VMess، Trojan، Shadowsocks-2022، VLESS-Reality (XTLS-Vision)، Hysteria2، WireGuard بومی، AmneziaWG |
| **ترنسپورت‌ها** | TCP، WebSocket، gRPC، XHTTP، HTTPUpgrade، mKCP، روی TLS یا Reality |
| **کاربران** | سقف حجم (کل یا جدا)، انقضا (ثابت یا از اولین اتصال)، محدودیت دستگاه، بازنشانی روزانه/هفتگی/ماهانه، دسترسی پروتکل و ورودی هر کاربر |
| **اشتراک‌ها** | یک لینک خودبه‌روزرسان برای هر کاربر، صفحه مصرف زنده، QR، فرمت‌های Clash/Mihomo و sing-box |
| **مسیریابی** | قوانین نقطه‌ای geosite/geoip/CIDR/دامنه/پروتکل، دسترسی مستقیم ایران و بایپس داخلی، مسدودسازی تبلیغات/تورنت/QUIC، DNS امن و ضد تحریم |
| **خروج** | مستقیم، مسدود، WARP (با لایسنس WARP+)، Tor، Psiphon، خروجی‌های سفارشی SOCKS/HTTP و اختصاص خروجی به هر ورودی |
| **تونل‌های ایران** | پل به خروج با Backhaul، BackPack، rathole یا wstunnel؛ انتقال TCP و UDP تا Hysteria2 کار کند |
| **دامنه و SSL** | Let's Encrypt یک‌کلیکی، Cloudflare کاملاً خودکار (DNS + وایلدکارت) یا گواهی Origin، همه با تمدید خودکار |
| **ناوگان** | ثبت و مدیریت چندین نود Nova از یک پنل، تجمیع کاربران و مصرف، تخصیص از راه دور |
| **API و ربات** | REST API با احراز توکن (`/api/v1`) و یک ربات کامل تلگرام با Mini App که کل پنل را در تلگرام باز می‌کند |
| **امنیت** | چند مدیر با نقش مالک و نماینده، احراز دومرحله‌ای (Google Authenticator)، بازنشانی رمز از سمت سرور |
| **خودکارسازی** | پشتیبان‌گیری شبانه (دیسک و تلگرام)، هشدارهای پیشگیرانه، به‌روزرسانی خودکار، تازه‌سازی آی‌پی تمیز، بررسی سلامت |
| **پنل** | انگلیسی، فارسی (راست‌به‌چپ)، روسی؛ جستجوی سراسری، راه‌انداز، راهنمای هر بخش و راهنمای کامل داخل پنل؛ تم روشن و تیره |

---

## 🏗️ معماری

```
                         :443 (TCP/UDP)
  کلاینت‌ها ───────────────────────────────►  نود Nova
                                              ├─ Xray-core   VLESS / VMess / Trojan / Reality / SS
                                              ├─ sing-box    Hysteria2 (UDP)
                                              ├─ AmneziaWG   وایرگارد مبهم‌شده
                                              └─ Nova agent  پنل · REST API · تلگرام · خودکارسازی
```

ایجنت یک پروسه Node.js با یک ذخیره‌ساز محلی SQLite است. پنل، REST API و ربات تلگرام همگی از توابع سرویس داخلی یکسانی استفاده می‌کنند.

---

## 📋 پیش‌نیازها

- یک VPS با **اوبونتو ۲۰.۰۴ به بالا** یا **دبیان ۱۱ به بالا** (x86_64 یا arm64)
- دسترسی **root**
- **دامنه** اختیاری است (فقط برای گواهی معتبر و Mini App تلگرام لازم می‌شود)

---

## 🔄 به‌روزرسانی

پنل نسخه‌های جدید را بررسی می‌کند و با یک کلیک به‌روز می‌شود، یا **به‌روزرسانی خودکار** را روشن کنید. کاربران، ورودی‌ها و تنظیمات حفظ می‌شوند.

---

<div align="center">

ساخته‌شده با دقت برای اینترنتی آزاد.

**Nova Server. تمام حقوق محفوظ است.**

</div>
