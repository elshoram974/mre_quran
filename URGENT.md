# عاجل: الناقص قبل الإصدار

اتكتب يوم 2026-11-27. الشغل كان على ويندوز من غير أي جهاز حقيقي، فكل اللي هنا **لسه ما اتعملش أو ما
اتجرّبش**. امسح البند لما يخلص، وامسح الملف لما يفضى.

## ٠. قبل أي build من ويندوز (يمنع الإصدار)

على جهاز الويندوز إعداد git `core.autocrlf=true`، وملفات `assets` النصية متنزّلة بنهايات سطور CRLF (٢٤ ملف).
التطبيق بيراجع SHA-256 لنص القرآن والأذكار وقت التشغيل، فأي **build من الجهاز ده** هيرمي
`QuranTextIntegrityException` والنص مش هيتحمّل. المشكلة قديمة ومش من التعديلات الأخيرة. البناء من الماك
سليم لأن الملفات هناك بتنزل LF.

الإصلاح: ملف `.gitattributes` في جذر المشروع فيه السطر ده، ويتعمله كوميت:

```gitattributes
# Bundled files are checked against their SHA-256: git must not touch them.
assets/** -text
```

وبعده على ويندوز (والشغل في `assets` متعمله كوميت) يتعاد تنزيل الملفات من Git Bash:

```sh
rm -r assets && git checkout -- assets
git ls-files --eol assets | grep "i/lf.*w/crlf"   # لازم ما يطبعش حاجة
```

- [ ] اتعمل، أو الإصدار كله بيتبني من الماك.

# الآيفون (يتعمل على الماك)

التجهيز: Flutter 3.50.0، وبعدها `flutter pub get` وشغّل على **آيفون حقيقي** (المحاكي مفيهوش مغناطيس).

## ١. الأهم: البوصلة على iOS بتقرأ المغناطيس الخام

### المشكلة

مكتبة `sensors_plus` (7.1.1) على iOS بتستخدم `CMMotionManager.startMagnetometerUpdates` وتبعت
`CMMagnetometerData.magneticField` زي ما هي
(`ios/sensors_plus/Sources/sensors_plus/FPPStreamHandlerPlus.swift` حوالي السطر 213–229). وده المجال
**ومعاه انحياز الجهاز نفسه**. على أندرويد المكتبة بتستخدم القراءة المعايَرة، فالمشكلة دي في iOS بس.

حجم الخطأ بالمحاكاة على `HeadingFilter` بتاعنا (مش قياس على جهاز):

| انحياز ثابت في الجهاز | القاهرة | لندن |
|---|---|---|
| 5 µT | 9° | 15° |
| 20 µT | 40° | لحد 180° |

يعني التطبيق ممكن يقول «أنت تواجه القبلة» وهو غلط. المشكلة موجودة من قبل التعديلات الأخيرة.

### الإصلاح المقترح

ناخد المجال **المعايَر** من Core Motion (`CMDeviceMotion.magneticField`: المجال من غير انحياز الجهاز) ونديه
لنفس حساب الـ Dart. الوحدة (µT) والمحاور نفسها، فحساب الاتجاه والميل ما يتغيرش.

**١) Swift** — مسودة ما اتبنتش. حطّها في آخر `ios/Runner/AppDelegate.swift` (عشان ما تحتاجش تعدّل مشروع Xcode)
وضيف `import CoreMotion` فوق:

```swift
/// The magnetic field without the device's own bias, in µT on the device's axes.
final class CompassFieldStream: NSObject, FlutterStreamHandler {
  private let motion = CMMotionManager()

  func onListen(
    withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    let frame = CMAttitudeReferenceFrame.xMagneticNorthZVertical
    guard motion.isDeviceMotionAvailable,
      CMMotionManager.availableAttitudeReferenceFrames().contains(frame)
    else {
      return FlutterError(code: "UNAVAILABLE", message: "No calibrated magnetometer", details: nil)
    }
    motion.deviceMotionUpdateInterval = 1.0 / 15.0
    motion.showsDeviceMovementDisplay = true
    motion.startDeviceMotionUpdates(using: frame, to: .main) { data, _ in
      guard let field = data?.magneticField, field.accuracy != .uncalibrated else { return }
      events([field.field.x, field.field.y, field.field.z])
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    motion.stopDeviceMotionUpdates()
    return nil
  }
}
```

وسجّلها جوه `didInitializeImplicitFlutterEngine`:

```swift
FlutterEventChannel(
  name: "net.mrecode.mre_quran/compass_field",
  binaryMessenger: engineBridge.applicationRegistrar.messenger()
).setStreamHandler(CompassFieldStream())
```

**٢) Dart** — في `lib/features/prayer/application/compass_provider.dart`، جوه `SensorsCompassSource.readings()`
استبدل `magnetometerEventStream(...)` بالدالة دي (محتاجة `flutter/foundation.dart` و`flutter/services.dart`)،
وسيب `headings.addWith(tilts, x, y, z)` زي ما هو:

```dart
/// The magnetic field in µT on the device's axes. On iOS it comes from Core
/// Motion, which takes the device's own bias out of it.
Stream<({double x, double y, double z})> _magneticField() {
  if (defaultTargetPlatform != TargetPlatform.iOS) {
    return magnetometerEventStream(samplingPeriod: SensorInterval.uiInterval)
        .map((event) => (x: event.x, y: event.y, z: event.z));
  }
  return const EventChannel('net.mrecode.mre_quran/compass_field')
      .receiveBroadcastStream()
      .map((event) {
        final values = event as List<Object?>;
        return (
          x: values[0]! as double,
          y: values[1]! as double,
          z: values[2]! as double,
        );
      });
}
```

الـ accelerometer يفضل من `sensors_plus` زي ما هو (المكتبة بتحوّل إشاراته على iOS لنفس اتجاه أندرويد).

### خلي بالك

- **ما تستخدمش `trueHeading`** ولا أي إطار «الشمال الحقيقي». التصحيح للشمال الحقيقي موجود في الـ Dart
  (`compassHeadingProvider` بيضيف الانحراف المغناطيسي للمكان المحفوظ)، و`CompassSource` لازم يفضل يرجّع
  الشمال **المغناطيسي**. لو التصحيح اتعمل مرتين الاتجاه هيغلط بقيمة الانحراف.
- لحد ما الجهاز يتعاير مفيش قراءات؛ النظام بيعرض شاشة تحريك الجهاز (`showsDeviceMovementDisplay`). اتأكد
  إنها بتظهر وإن البوصلة بتشتغل بعدها.
- بديل لو الطريقة دي ما اشتغلتش: `CLLocationManager.startUpdatingHeading` واستخدم `magneticHeading`.
- شرح Apple: [CMDeviceMotion.magneticField](https://developer.apple.com/documentation/coremotion/cmdevicemotion/magneticfield)

### مقبول لما

- [ ] شغّل «استخدام الشمال الحقيقي» في إعدادات تطبيق البوصلة بتاع Apple، واتأكد إن الاتجاه عندنا قريب منه
      (فرق حوالي ٥° أو أقل) في ٤ اتجاهات على الأقل.
- [ ] لفّة كاملة بالموبايل بتغطي ٣٦٠°.
- [ ] الصفحة بتقفل الحساسات لما تخرج منها.

## ٢. تأكد من `NSMotionUsageDescription`

ملف README بتاع `sensors_plus` بيقول إن المفتاح ده مطلوب في `ios/Runner/Info.plist` وإلا التطبيق يقع،
وهو **مش موجود** عندنا. نفس الملف بيربطه بالبارومتر، واحنا مش بنستخدمه.

- [ ] افتح صفحة القبلة على آيفون حقيقي. لو وقع أو ظهرت رسالة خصوصية في الـ log، ضيف المفتاح بنص عربي
      وإنجليزي، وحدّث `docs/STORE_COMPLIANCE.md`.

## ٣. التابلت (آيباد وأندرويد): دوران الشاشة

اتجاه البوصلة محسوب من **حافة الجهاز العليا**، والقرص مرسوم على **أعلى الشاشة**، فلو الشاشة ملفوفة الاتجاه
بيغلط ٩٠° أو ١٨٠°. صفحة القبلة بقت بتتثبّت رأسي على الموبايل. أما الشاشات اللي أصغر ضلع فيها 600 أو أكتر
(آيباد، تابلت أندرويد، موبايل مفتوح) فالنظام بيتجاهل الطلب، فالصفحة **عليها تنبيه ومش بتأكد «أنت تواجه
القبلة» خالص**، حتى وهي رأسي.

الإصلاح (كود native): اقرأ دوران الشاشة (على iOS `UIWindowScene.interfaceOrientation`، وعلى أندرويد
`Display.rotation`) وزوّده على الاتجاه، وبعدين شيل التنبيه (`turned: !upright` في `QiblaPage.build`).
القيم المتوقعة على iOS:

| اتجاه الواجهة | يتضاف |
|---|---|
| `portrait` | 0° |
| `landscapeRight` | 90° |
| `portraitUpsideDown` | 180° |
| `landscapeLeft` | 270° |

القيم دي مستنتجة من تعريف المحاور، **اتأكد منها على الجهاز**. ونفس الدوران لازم يتطبّق على فقاعة الميل.

- [ ] الاتجاه والفقاعة صح في الأربع أوضاع على آيباد.

## ٤. فحص التعديلات الجديدة على الآيفون

- [ ] القبلة أثناء التحميل: مؤشر التحميل في الأب بار الزجاجي شكله مظبوط، والبوصلة بتدخل بحركة الارتداد مرة
      واحدة، ومفيش قفزة لما البيانات توصل. مع «تقليل الحركة» مفيش ارتداد.
- [ ] فقاعة الميل: ارفع الحافة اليمين فالفقاعة تروح يمين، وارفع الحافة العليا فتروح لفوق.
- [ ] المصحف: شريحة الحزب جنب الجزء في ترويسة الصفحة، على شاشة صغيرة (SE) وعلى الآيباد بصفحتين، من غير
      قص أو تداخل مع النوتش.
- [ ] الدوران: لف المصحف أفقي، افتح القبلة (تبقى رأسي)، ارجع (المصحف يرجع أفقي)، واخرج من المصحف (التطبيق
      يرجع لوضعه العادي).
- [ ] راجع النصوص العربية الجديدة في صفحة القبلة (`qibla*` في `lib/l10n/app_ar.arb`).

# أندرويد

## ٥. فحص على موبايل أندرويد حقيقي

ما اتجرّبش على أي جهاز أو محاكي.

- [ ] القبلة: الاتجاه قريب من بوصلة Google Maps أو أي بوصلة بتعرض الشمال الحقيقي، في ٤ اتجاهات.
- [ ] فقاعة الميل بتروح ناحية الحافة المرفوعة، و«أنت تواجه القبلة» ما تظهرش والموبايل مايل.
- [ ] موبايل من غير مغناطيس: الصفحة بتقول إن مفيش بوصلة ومن غير فقاعة.
- [ ] تحميل الصفحة: شريط التحميل في الأب بار ودخول البوصلة بالارتداد.
- [ ] المصحف: شريحة الحزب في الترويسة على شاشة صغيرة، وضغطتها بتفتح فهرس الأحزاب.
- [ ] الدوران: نفس خطوة الآيفون (المصحف أفقي ← القبلة رأسي ← يرجع أفقي)، وعلى تابلت يظهر تنبيه دوران الشاشة.

# متأجّل (تحسينات مش مانعة)

## ٦. القبلة

- [ ] **كشف التشويش المغناطيسي:** مقارنة قوة المجال المقاسة بقوة المجال المتوقعة للمكان (النموذج المغناطيسي
      بيحسبها) وعدم تأكيد القبلة لو بعيدة. محتاج `CompassSource` يمرّر قوة المجال، وحدّ يتظبط على أجهزة حقيقية.
      بعد إصلاح الآيفون (بند ١) قيّم هل لسه محتاجينه.
- [ ] **ثبات «تواجه القبلة» عند الحافة:** الدخول عند ٤° والخروج عند ٦° عشان ما ترمّشش.
- [ ] **أندرويد:** قراءة الاتجاه من حساس rotation vector مع حالة المعايرة (كود Kotlin).
- [ ] **قبل 2030:** النموذج المغناطيسي WMM2025 صلاحيته لآخر 2029؛ تتحدّث المعاملات من NOAA.

## ٧. ترويسة المصحف

- [ ] على شاشة عرضها 360 بخط مكبّر 1.3، اسم «المرسلات» بيتقص في صفحتي ٥٨٠ و٥٨١. القياس كان بخطوط
      أندرويد؛ خط iOS ما اتقاسش (راجع بند ٤).

# متنوّع

## ٨. اختبارات بتفشل على ويندوز من قبل التعديلات

مع ملفات `assets` بنهايات LF: صور golden التمانية (البند ٩)، واختبار واحد في `voice_store_test.dart`
(بيقارن المسار بـ `/` وويندوز بيرجّع `\`). وفيه اختبارات بتفشل أحياناً لما الجهاز مضغوط وبتنجح لوحدها:
`page_prefetcher_test.dart` (بتفشل على الكود قبل التعديلات برضه) و`svg_page_retry_test.dart` (بيستنى ٣ ثواني
حقيقية للصفحة، ونجح لوحده على الكود الجديد).

آخر تشغيل كامل بعد دمج التعديلات: ٢٠٥٠ نجح و١٢ فشلوا، كلهم من الأنواع دي.

## ٩. صور الـ golden بتاعة المصحف

الصور التمانية في `test/features/mushaf/goldens/` بترسم الصفحة بترويستها، فشريحة الحزب غيّرتها. على ويندوز
الصور ما بتطابقش حتى من غير أي تعديل، فلازم تتحدّث من الماك:

```sh
flutter test test/features/mushaf/mushaf_golden_test.dart
# راجع الفروق في test/features/mushaf/failures: المفروض شريحة الحزب بس
flutter test --update-goldens test/features/mushaf/mushaf_golden_test.dart
```

- [ ] الصور اتراجعت واتعملها كوميت.
