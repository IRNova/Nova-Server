<div align="center" dir="rtl">

<img src="https://raw.githubusercontent.com/iiviirv/irnova-site/main/brand/nova-logo-gradient.svg" width="70" alt="نوا سرور">

<div align="left">
  <a href="README.md">🇬🇧 English</a>
</div>

# 🌟 نوا سرور (Nova Server)

**پنل کامل نوا روی VPS خودت.**

هستهٔ xray به‌همراه عامل نود نوا پشت یک پورت عمومی (۴۴۳)، که از همان اپ نوا، مرورگر یا
ربات تلگرام مدیریت می‌شود. چندپروتکلی (VLESS، Trojan، Shadowsocks، Hysteria2)، بهینه‌سازی
به‌تفکیک اپراتور، و TLS با افزودن دامنه. همه‌چیز روی **سرور خودت** اجرا می‌شود و هیچ‌چیز از
ترافیک تو بیرون فرستاده نمی‌شود.

[![License](https://img.shields.io/badge/license-MIT-purple?style=for-the-badge)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Debian%20%2F%20Ubuntu-0ea5e9?style=for-the-badge&logo=linux&logoColor=white)](https://github.com/IRNova/Nova-Server)
[![Stars](https://img.shields.io/github/stars/IRNova/Nova-Server?style=for-the-badge&color=8957e5)](https://github.com/IRNova/Nova-Server)

</div>

---

## 🌐 لینک‌ها

<div align="center">

[![Website](https://img.shields.io/badge/🌐%20سایت-novaproxy.online-0ea5e9?style=for-the-badge)](https://novaproxy.online/)
[![Telegram Channel](https://img.shields.io/badge/✈️%20کانال%20تلگرام-@irnova__proxy-0ea5e9?style=for-the-badge&logo=telegram)](https://t.me/irnova_proxy)
[![Telegram Group](https://img.shields.io/badge/👥%20گروه%20تلگرام-@irnovaproxy__group-0ea5e9?style=for-the-badge&logo=telegram)](https://t.me/irnovaproxy_group)
[![YouTube](https://img.shields.io/badge/▶️%20یوتیوب-@novaproxyir-ff0000?style=for-the-badge&logo=youtube)](https://www.youtube.com/@novaproxyir)
[![X (Twitter)](https://img.shields.io/badge/𝕏%20شبکه%20ایکس-@irNovaProxy-000000?style=for-the-badge&logo=x)](https://x.com/irNovaProxy)
[![Instagram](https://img.shields.io/badge/📸%20اینستاگرام-@irnova__proxy-E4405F?style=for-the-badge&logo=instagram)](https://www.instagram.com/irnova_proxy)

</div>

---

<div dir="rtl">

## 📖 نوا سرور چیست؟

نوا سرور، سمت VPSِ نواست. با یک دستور، هستهٔ **xray** و **عامل نود نوا** روی سرور Debian یا Ubuntu خودت نصب می‌شوند و طوری به هم وصل می‌شوند که یک پورت عمومی (۴۴۳) هم پنل مدیریت و هم تانل را سرو می‌کند. مدیریت از همان اپ نوا، مرورگر روی `https://your-vps` یا ربات تلگرام توکار انجام می‌شود.

جایی که Cloudflare Worker نمی‌تواند TCP بومی اجرا کند یا UDP را عبور دهد، نوا سرور می‌تواند. یعنی **VLESS** کامل، **UDP واقعی برای تماس صوتی و تصویری**، و **Hysteria2** برای گیمینگ کم‌تأخیر، همه روی زیرساختی که خودت کنترلش می‌کنی.

**چه چیزی متفاوتش می‌کند:**
- 🔒 **سرور تو، ترافیک تو.** هیچ‌چیز لاگ نمی‌شود و هیچ‌چیز بیرون فرستاده نمی‌شود.
- ⚡ **نصب یک‌خطی.** xray و کل پنل نوا، ظرف چند دقیقه سیم‌کشی می‌شوند.
- 🧩 **چندپروتکلی.** VLESS، Trojan، Shadowsocks و Hysteria2 با پورت UDP قابل‌تنظیم برای جابه‌جایی پورت.
- 🌍 **بهینه‌سازی به‌تفکیک اپراتور.** fingerprint و fragmentation به‌صورت خودکار برای هر اپراتور تنظیم می‌شود.
- 🔐 **TLS با افزودن دامنه.** یک دامنه به سرور اشاره بده تا گواهی واقعی بگیری (Let's Encrypt یا Cloudflare Origin)، یا با آی‌پی عمومی و گواهی self-signed کار کن.
- 📱 **مدیریت از همه‌جا.** از اپ نوا، مرورگر یا تلگرام.

---

## ⚡ نصب سریع

روی VPS خودت (Debian یا Ubuntu، به‌صورت root) اجرا کن:

</div>

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRNova/Nova-Server/main/nova-node.sh)
```

<div dir="rtl">

متغیرهای محیطی اختیاری:

- `NOVA_ADMIN_PASS=...` رمز ادمین پنل را تعیین می‌کند (اگر تنظیم نشود، یک رمز تصادفی ساخته می‌شود).
- `NOVA_DOMAIN=...` دامنه‌ای که به این سرور اشاره می‌کند. بدون دامنه، نود از آی‌پی عمومی با گواهی self-signed استفاده می‌کند.

وقتی تمام شد، `https://your-vps` را در مرورگر باز کن یا نود را مستقیم از اپ نوا اضافه کن.

---

## 📋 پیش‌نیازها

- یک **VPS با دسترسی root SSH** (Debian یا Ubuntu).
- اختیاری: یک **دامنه** که به سرور اشاره کند، برای گواهی TLS معتبر.

---

## 🛠 چطور کار می‌کند

xray روی پورت ۴۴۳ گواهی TLS را می‌بندد و بر اساس مسیر توزیع می‌کند: مسیرِ تانل به اینباندهای VLESS، VMess، Trojan و Hysteria2 روی loopback می‌رود و بقیهٔ درخواست‌ها به پنل HTTP و داشبورد مرورگرِ عامل. عامل از اپ نوا، مرورگر یا ربات تلگرام مدیریت می‌شود و همه‌چیز کاملاً روی سرور خودت اجرا می‌شود.

---

## 💜 حمایت

اگر نوا سرور به‌دردت خورد، لطفاً **⭐ به ریپازیتوری ستاره بده**. همین پروژه را زنده و رایگان نگه می‌دارد.

</div>

<div align="center">

### ⭐ [به نوا سرور در گیت‌هاب ستاره بده](https://github.com/IRNova/Nova-Server) ⭐

| ارز | آدرس |
|------|---------|
| **TON** | `UQD51lGC35rP_SbVYgbFA7CEEii4GVMFgqj4N8fiGi6m425w` |

</div>

---

<div dir="rtl">

## 🙏 دست‌اندرکاران

با ❤️ برای اینترنت آزاد و باز.

- [@iiviirv](https://github.com/iiviirv) — مشارکت‌کننده
- [Xray-core](https://github.com/XTLS/xray-core)
- [نوا پروکسی](https://github.com/IRNova/Nova-Proxy) — سمت Cloudflare Worker نوا

---

## مجوز

MIT، فایل [LICENSE](LICENSE) را ببین.

</div>

---

<div align="center">

ساخته‌شده برای ایران <img src="https://raw.githubusercontent.com/IRNova/Nova-Proxy/main/flag-iran.svg" height="16" alt="Iran (Lion and Sun)" /> و هر کسی که به اینترنت آزاد و باز نیاز دارد.
**هیچ‌چیز از ترافیک تو لاگ نمی‌شود. سرور مال توست.**

📖 [نسخهٔ انگلیسی](README.md)

</div>
