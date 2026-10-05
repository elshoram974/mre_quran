# Permission requests for Quran fonts and layout data

Drafts to send before any font, layout file, or image enters the app. Fill the
`[brackets]`. Keep every reply: it is the written approval the licences ask for
(see `docs/QURAN_SOURCES.md`).

## Which font, and why

**Target: QCF v4 (Madinah Mushaf, 1441 H) in light mode, no page images.**

- It reproduces the printed Madinah Mushaf line by line, so page 1, 2, 42, and 604
  match the paper copy.
- About 47 font files instead of 604 (QCF v1/v2), so the install stays small.
- Text comes from Tanzil (clear CC BY 3.0). The fonts only draw the glyphs.

The KFGQPC licence says the font may not be reproduced or modified without
written approval, so we ask first. Two channels, in this order:

1. **Quran Foundation** publishes bundling terms for fonts and Mushaf images
   obtained through its API or documented CDN. We need confirmation that QCF v4 is
   covered.
2. **King Fahd Glorious Quran Printing Complex (KFGQPC)** owns the fonts. Ask for
   written approval if Quran Foundation cannot confirm.

## Email 1: Quran Foundation (English)

**To:** developers@quran.com
**Subject:** Bundling QCF v4 fonts and Madinah layout data in a free Quran app

Assalamu alaikum,

I am building [APP NAME], a free, ad-free Quran reading app for Android and iOS
with no analytics or accounts. It renders the Madinah Mushaf (1441 H) page by page
from fonts, with no page images.

Your developer terms say fonts and Mushaf images obtained through your APIs or
documented CDN may be bundled when the app credits Quran Foundation and ships them
only as part of the app. Before I rely on that, could you confirm:

1. Are the QCF v4 fonts (Madinah Mushaf, 1441 H) covered by those terms for
   bundling inside the app package?
2. Is the page, line, and word layout data from your API (or Quranic Universal
   Library) covered too, and under what licence?
3. Are tajweed-coloured and plain variants both covered?
4. What attribution text and placement do you require?
5. Do the terms require a Developer Console account for apps that only bundle the
   files and never call the API at runtime?

The Quran text itself comes from Tanzil (CC BY 3.0), unmodified, with attribution.
The app is free and will stay free. I am happy to share a build or screenshots.

Jazakum Allahu khairan,
[YOUR NAME]
[APP NAME] · [WEBSITE OR STORE LINK] · [CONTACT EMAIL]

## Email 2: KFGQPC (Arabic first, English below)

**To:** [KFGQPC contact address, from fonts.qurancomplex.gov.sa]
**Subject:** طلب إذن استخدام خط مصحف المدينة (QCF v4) في تطبيق مجاني

السلام عليكم ورحمة الله وبركاته،

أعمل على تطبيق [اسم التطبيق]، وهو تطبيق مجاني بلا إعلانات ولا تتبع ولا حسابات،
لقراءة القرآن الكريم على أندرويد وآيفون. يعرض التطبيق صفحات مصحف المدينة النبوية
(طبعة 1441 هـ) كما هي في المطبوع، اعتمادًا على خطوط مجمع الملك فهد لطباعة المصحف
الشريف، دون أي تعديل في الخطوط أو في نص الآيات.

نص رخصة الخط المنشورة يشترط موافقة كتابية قبل إعادة إنتاج الخط أو تعديله. فنرجو
التكرم بالإفادة عن:

1. هل يجوز تضمين خطوط QCF v4 داخل حزمة التطبيق دون تعديل؟
2. هل يجوز الاستخدام ضمن تطبيق مجاني، وهل يختلف الحكم لو كان التطبيق مدفوعًا لاحقًا؟
3. ما صيغة الإسناد والعبارة المطلوبة وموضعها في التطبيق؟
4. هل هناك شروط إضافية (إصدار الخط، اللغات، المنصات)؟

وجزاكم الله خيرًا.

[الاسم] · [اسم التطبيق] · [رابط الموقع أو المتجر] · [البريد]

---

Assalamu alaikum,

I am building [APP NAME], a free Quran app with no ads, analytics, or accounts, for
Android and iOS. It shows the Madinah Mushaf (1441 H) using the KFGQPC fonts,
without modifying the fonts or the Quran text.

The published font licence requires written approval before the font is reproduced
or modified. Could you confirm:

1. May the QCF v4 fonts be bundled unmodified inside the app package?
2. Is use in a free app allowed, and would the answer change if the app were paid?
3. What attribution wording and placement do you require?
4. Are there any other conditions (font version, languages, platforms)?

Jazakum Allahu khairan,
[YOUR NAME] · [APP NAME] · [LINK] · [EMAIL]

## Before you send

- Replace every `[bracket]`. Use a real contact address and a link to the app or a
  landing page.
- Do not attach fonts or content from other sources.
- Save each reply in `docs/permissions/` with the date. Cite it in
  `docs/QURAN_SOURCES.md` next to the source it approves.
- Nothing is bundled until a reply says yes. The Mushaf stays blocked until then.

## Quranic Universal Library (QUL)

Layout data is also available from QUL. Its resource pages link terms of use but
state no licence. Read those terms, record them in `docs/QURAN_SOURCES.md`, and ask
Tarteel if anything is unclear.
