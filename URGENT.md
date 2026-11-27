# عاجل: الناقص في الآيفون (يتعمل على الماك)

اتكتب يوم 2026-11-27. كل اللي هنا **ما اتبناش وما اتجرّبش على آيفون**، لأن الشغل كان على ويندوز.
امسح الملف ده بعد ما تخلّص البنود، وسجّل القرار في `docs/DECISIONS.md`.

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

**٢) Dart** — في `lib/features/prayer/application/compass_provider.dart`، جوه `SensorsCompassSource`
استبدل `magnetometerEventStream(...)` بالدالة دي (محتاجة `flutter/foundation.dart` و`flutter/services.dart`).
هذا مبني على شكل الملف بعد كوميت مؤشر الميل:

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

- **ما تستخدمش `trueHeading`** ولا أي إطار «الشمال الحقيقي». تصحيح الشمال الحقيقي بيتضاف في الـ Dart،
  ولو اتعمل مرتين الاتجاه هيغلط بقيمة الانحراف المغناطيسي.
- لحد ما الجهاز يتعاير مفيش قراءات؛ النظام بيعرض شاشة تحريك الجهاز (`showsDeviceMovementDisplay`). اتأكد
  إنها بتظهر وإن البوصلة بتشتغل بعدها.
- بديل لو الطريقة دي ما اشتغلتش: `CLLocationManager.startUpdatingHeading` واستخدم `magneticHeading`.
- شرح Apple: [CMDeviceMotion.magneticField](https://developer.apple.com/documentation/coremotion/cmdevicemotion/magneticfield)

### مقبول لما

- [ ] الاتجاه قريب من تطبيق البوصلة بتاع Apple (فرق حوالي ٥° أو أقل) في ٤ اتجاهات على الأقل.
      لو تصحيح الشمال الحقيقي نزل، شغّل «استخدام الشمال الحقيقي» في إعدادات البوصلة؛ لو لسه، اقفله.
- [ ] لفّة كاملة بالموبايل بتغطي ٣٦٠°.
- [ ] الصفحة بتقفل الحساسات لما تخرج منها.

## ٢. تأكد من `NSMotionUsageDescription`

ملف README بتاع `sensors_plus` بيقول إن المفتاح ده مطلوب في `ios/Runner/Info.plist` وإلا التطبيق يقع،
وهو **مش موجود** عندنا. نفس الملف بيربطه بالبارومتر، واحنا مش بنستخدمه.

- [ ] افتح صفحة القبلة على آيفون حقيقي. لو وقع أو ظهرت رسالة خصوصية في الـ log، ضيف المفتاح بنص عربي
      وإنجليزي، وحدّث `docs/STORE_COMPLIANCE.md`.

## ٣. الآيباد: دوران الشاشة

اتجاه البوصلة محسوب من **حافة الجهاز العليا**، والقرص مرسوم على **أعلى الشاشة**. فلو الشاشة ملفوفة الاتجاه
بيغلط ٩٠° أو ١٨٠°. على الموبايل هنثبّت الصفحة رأسي من الـ Dart، لكن الآيباد بيتجاهل الطلب ده.

الإصلاح: اقرأ `UIWindowScene.interfaceOrientation` وزوّد على الاتجاه:

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

## ٥. صور الـ golden بتاعة المصحف

الصور التمانية في `test/features/mushaf/goldens/` بترسم الصفحة بترويستها، فشريحة الحزب غيّرتها. على ويندوز
الصور ما بتطابقش حتى من غير أي تعديل، فلازم تتحدّث من الماك:

```sh
flutter test test/features/mushaf/mushaf_golden_test.dart
# راجع الفروق في test/features/mushaf/failures: المفروض شريحة الحزب بس
flutter test --update-goldens test/features/mushaf/mushaf_golden_test.dart
```

- [ ] الصور اتراجعت واتعملها كوميت.
