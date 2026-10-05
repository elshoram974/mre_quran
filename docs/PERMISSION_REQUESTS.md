# Permission requests for Quran fonts and layout data

Drafts to send before any font, layout file, or image enters the app. Fill the
`[brackets]`. Keep every reply: it is the written approval the licences ask for
(see `docs/QURAN_SOURCES.md`).

## Which font and which images

Measured with HEAD requests to the Quran Foundation font CDN (nothing downloaded), TTF files, which
is the only format Flutter loads on phones (WOFF/WOFF2 are for browsers):

| Font | Layout | One page | All 604 pages |
|---|---|---|---|
| QCF V1 (1405 H) | per-page fonts | 27 to 160 KB, about 90 KB average | about 55 MB |
| QCF V2 (1421/1423 H) | per-page fonts | 160 to 620 KB, about 370 KB average | about 220 MB |
| QCF V4 Tajweed (colour, COLRv1) | per-page fonts | not measured (URL differs) | not measured |
| QPC Hafs / Uthmani (Unicode) | one font for the whole Quran | not measured | one file |

The page averages come from four sample pages each (1, 2, 300, 604), so totals are rough.

**Decision for the light default mode:** one bundled Unicode font (QPC Hafs, Uthmani script), with Tanzil
text and line breaks from the layout data. It stays small and does not need 604 downloads. Lines follow the
Madinah Mushaf line by line; the letter shapes come from one font, not the per-page glyphs.

**Optional on-demand pack:** QCF V1 or V2 page fonts for pixel-exact pages, downloaded per page, cached, and
deletable. V1 is about 4 times lighter than V2, so ask about V1 first. These must never be bundled.

**Later, one pack at a time:** Mushaf page images. Quran Foundation offers Uthmani Tajweed and black
page images through its Content API, under the same bundling terms. Ask for the CDN pattern, format
(WebP preferred), resolution, and size per page before deciding anything.

Note: the "about 47 files" figure belongs to a third-party QCF4 package. Quran Foundation's V4 Tajweed is
per-page like V1 and V2. COLRv1 colour support in Flutter is unverified and needs a device test.

The KFGQPC licence says the fonts may not be reproduced or modified without written approval, so we ask
first. Two channels, in this order:

1. **Quran Foundation** publishes bundling terms for fonts and Mushaf images obtained through its API or
   documented CDN. We need confirmation for the exact fonts below.
2. **King Fahd Glorious Quran Printing Complex (KFGQPC)** owns the fonts. Ask for written approval if Quran
   Foundation cannot confirm.

## Email 1: Quran Foundation (English)

**To:** developers@quran.com
**Subject:** Bundling Quran fonts, layout data, and page images in a free Quran app

Assalamu alaikum,

I am building [APP NAME], a free, ad-free Quran reading app for Android and iOS
with no analytics or accounts. It renders the Madinah Mushaf (1441 H) page by page
from fonts, with no page images.

Your developer terms say fonts and Mushaf images obtained through your APIs or
documented CDN may be bundled when the app credits Quran Foundation and ships them
only as part of the app. Before I rely on that, could you confirm:

1. May the Unicode Uthmani font (QPC Hafs) be bundled inside the app package? It is
   our default, light mode.
2. May the QCF V1 and V2 page fonts be downloaded on demand by the app, cached on
   the device, and deleted by the user? Is bundling them also allowed, or only
   on-demand download?
3. Is the page, line, and word layout data from your API (or Quranic Universal
   Library) covered too, and under what licence?
4. Are the Mushaf page images (Uthmani and Tajweed) covered by the same terms? What
   are the CDN pattern, format, resolution, and size per page?
5. What attribution text and placement do you require?
6. Do the terms require a Developer Console account for apps that only bundle or
   cache the files and never call the API at runtime?

The Quran text itself comes from Tanzil (CC BY 3.0), unmodified, with attribution.
The app is free and will stay free. I am happy to share a build or screenshots.

Jazakum Allahu khairan,
[YOUR NAME]
[APP NAME] · [WEBSITE OR STORE LINK] · [CONTACT EMAIL]

## Email 2: KFGQPC (Arabic first, English below)

**To:** [KFGQPC contact address, from fonts.qurancomplex.gov.sa]
**Subject:** طلب إذن استخدام خطوط مصحف المدينة في تطبيق مجاني

السلام عليكم ورحمة الله وبركاته،

أعمل على تطبيق [اسم التطبيق]، وهو تطبيق مجاني بلا إعلانات ولا تتبع ولا حسابات،
لقراءة القرآن الكريم على أندرويد وآيفون. يعرض التطبيق صفحات مصحف المدينة النبوية
(طبعة 1441 هـ) كما هي في المطبوع، اعتمادًا على خطوط مجمع الملك فهد لطباعة المصحف
الشريف، دون أي تعديل في الخطوط أو في نص الآيات.

نص رخصة الخط المنشورة يشترط موافقة كتابية قبل إعادة إنتاج الخط أو تعديله. فنرجو
التكرم بالإفادة عن:

1. هل يجوز تضمين خط حفص (الرسم العثماني) داخل حزمة التطبيق دون تعديل؟
2. هل يجوز تنزيل خطوط QCF الخاصة بكل صفحة (الإصدار الأول والثاني) عند الطلب وحفظها على الجهاز؟
3. هل يجوز الاستخدام ضمن تطبيق مجاني، وهل يختلف الحكم لو كان التطبيق مدفوعًا لاحقًا؟
4. ما صيغة الإسناد والعبارة المطلوبة وموضعها في التطبيق؟
5. هل هناك شروط إضافية (إصدار الخط، اللغات، المنصات)؟

وجزاكم الله خيرًا.

[الاسم] · [اسم التطبيق] · [رابط الموقع أو المتجر] · [البريد]

---

Assalamu alaikum,

I am building [APP NAME], a free Quran app with no ads, analytics, or accounts, for
Android and iOS. It shows the Madinah Mushaf (1441 H) using the KFGQPC fonts,
without modifying the fonts or the Quran text.

The published font licence requires written approval before the font is reproduced
or modified. Could you confirm:

1. May the Uthmani Hafs font be bundled unmodified inside the app package?
2. May the per-page QCF fonts be downloaded on demand and cached on the device?
3. Is use in a free app allowed, and would the answer change if the app were paid?
4. What attribution wording and placement do you require?
5. Are there any other conditions (font version, languages, platforms)?

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
