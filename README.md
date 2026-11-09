# دفتر الطلبيات

موقع لتسيير طلبيات البائعات قبل إرسالها إلى Ecotrack.

- **الواجهة:** Cloudflare Pages (المشروع `daftari`) — الملفات اللي في هذا المجلد.
- **قاعدة البيانات:** Supabase (المشروع `dafter-talabat`).
- **ملفات Supabase:** في مجلد `supabase/`.

## التحديث
Cloudflare ← Workers & Pages ← `daftari` ← Create deployment ← رفع الملفات:
`index.html` · `quick.html` · `sw.js` · `manifest.json` · `manifest-quick.json` · `icon-192.png` · `icon-512.png`

> ⚠️ ملفات التنبيهات (الدالة smart-responder وملفات SQL اللي فيها المفاتيح السرية) ماشي هنا، لأن المستودع عام. محفوظة في نسخة خاصة.
