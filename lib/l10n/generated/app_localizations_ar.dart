// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'مصحفي';

  @override
  String get reader => 'المصحف';

  @override
  String get bookmarks => 'العلامات';

  @override
  String get settings => 'الإعدادات';

  @override
  String get search => 'بحث';

  @override
  String get noBookmarksTitle => 'لا توجد علامات بعد';

  @override
  String get noBookmarksBody =>
      'اضغط مطولًا على أي آية في المصحف لإضافة علامة.';

  @override
  String get appearance => 'المظهر';

  @override
  String get theme => 'السمة';

  @override
  String get themeSystem => 'حسب الجهاز';

  @override
  String get themeLight => 'كريمي';

  @override
  String get themeDark => 'كحلي';

  @override
  String get themeSepia => 'ورقي';

  @override
  String get themeWhite => 'أبيض';

  @override
  String get themeGreen => 'أخضر';

  @override
  String get themeBlack => 'أسود';

  @override
  String get pageTheme => 'لون الصفحة';

  @override
  String get accentColor => 'اللون المميّز';

  @override
  String get accentColorHint => 'لأرقام الآيات والتظليل والأزرار';

  @override
  String get accentGold => 'ذهبي';

  @override
  String get accentEmerald => 'زمردي';

  @override
  String get accentTeal => 'فيروزي';

  @override
  String get accentBlue => 'أزرق';

  @override
  String get accentIndigo => 'نيلي';

  @override
  String get accentRose => 'وردي';

  @override
  String get accentCrimson => 'قرمزي';

  @override
  String get accentBrown => 'بني';

  @override
  String get language => 'اللغة';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get reduceMotion => 'تقليل الحركة';

  @override
  String get reduceMotionDescription => 'استخدم أقل قدر من الحركة في الواجهة.';

  @override
  String get arabicDigits => 'الأرقام العربية';

  @override
  String get arabicDigitsDescription => 'اعرض الأرقام العربية في الواجهة.';

  @override
  String get privacy => 'الخصوصية';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get privacyPolicyDescription => 'ما يحفظه التطبيق، وما يرسله، ولماذا';

  @override
  String get crashReports => 'تقارير الأعطال';

  @override
  String get crashReportsDescription =>
      'تُرسَل تقارير أعطال تقنية لا تحتوي على بياناتك الشخصية، لنصلح الأخطاء بسرعة. يمكنك إيقافها.';

  @override
  String get about => 'عن التطبيق والنسب';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get settingsLoadError => 'تعذّر تحميل الإعدادات. حاول مرة أخرى.';

  @override
  String get creditsTitle => 'النسب والمصادر';

  @override
  String get contactUs => 'تواصل معنا';

  @override
  String get contactWhatsApp => 'واتساب';

  @override
  String get contactEmail => 'البريد الإلكتروني';

  @override
  String get contactFailed => 'لا يوجد على جهازك ما يفتح هذا.';

  @override
  String appVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get hintNever => 'لا تذكرني مرة أخرى';

  @override
  String get hintLater => 'لاحقًا';

  @override
  String get hintPermissionsTitle => 'سنطلب إذنين';

  @override
  String get hintPermissionsBody =>
      'لننبّهك بالأذان نحتاج إذن الإشعارات، ولحساب المواقيت نحتاج موقعك. يمكنك اختيار موقع تقريبي أو دقيق، أو تحديده على الخريطة. تُحسب المواقيت على جهازك.';

  @override
  String get hintPermissionsAction => 'متابعة';

  @override
  String get hintTryAdhanTitle => 'جرّب الأذان الآن';

  @override
  String get hintTryAdhanBody =>
      'اسمع التنبيه كما سيأتي وقت الصلاة، وتأكد أن الصوت مسموع، قبل أول صلاة.';

  @override
  String get hintTryAdhanAction => 'جرّب الآن';

  @override
  String get hintWidgetsTitle => 'المواقيت على شاشتك الرئيسية';

  @override
  String get hintWidgetsBody =>
      'ضع مواقيت الصلاة أو المسبحة أو ذكرًا على شاشتك الرئيسية، لتراها دون أن تفتح التطبيق.';

  @override
  String get hintWidgetsAction => 'اختر أداة';

  @override
  String get hintWidgetsManual =>
      'اضغط مطولًا على الشاشة الرئيسية، ثم «الأدوات»، وابحث عن «مصحفي».';

  @override
  String get widgetsTitle => 'أدوات الشاشة الرئيسية';

  @override
  String get widgetsIntro =>
      'اعرض مواقيت الصلاة، وعُدّ تسبيحك، وتابع الأذكار من الشاشة الرئيسية.';

  @override
  String get widgetsPreviewHint =>
      'الصور تعرض التصميم الافتراضي. اختياراتك تُطبّق على الويدجت في الشاشة الرئيسية.';

  @override
  String get widgetAppearance => 'ألوان الويدجت';

  @override
  String get widgetDefaultStyle => 'ألوان كل ويدجت الأصلية';

  @override
  String get widgetStyleSaveFailed => 'تعذّر حفظ لون الويدجت. حاول مرة أخرى.';

  @override
  String get widgetSizeSmall => 'أصغر مقاس على أندرويد: خليتان عرضًا وصف واحد.';

  @override
  String get widgetSizeTall =>
      'المقاس المقترح على أندرويد: خليتان عرضًا وصفان؛ ويمكن تغيير حجمه.';

  @override
  String get widgetSizeWide => 'أصغر مقاس على أندرويد: ثلاث خلايا عرضًا وصفان.';

  @override
  String get widgetIosTasbihHint => 'العد من الويدجت يتطلب iOS 17 أو أحدث.';

  @override
  String get widgetsAdd => 'إضافة';

  @override
  String get widgetsAddAsked =>
      'أكّد الإضافة في النافذة التي تظهر لتوضع الأداة على شاشتك.';

  @override
  String get widgetsStepsIos =>
      'لإضافة أداة: اضغط مطولًا على مكان فارغ في الشاشة الرئيسية، ثم «+» في الأعلى، وابحث عن «مصحفي»، واختر الأداة ومقاسها، ثم «إضافة أداة».';

  @override
  String get widgetPrayerCard => 'بطاقة الصلاة';

  @override
  String get widgetPrayerCardDescription =>
      'الصلاة القادمة والوقت المتبقي، وصلوات اليوم والشروق والتاريخ.';

  @override
  String get widgetNextPrayer => 'الصلاة القادمة';

  @override
  String get widgetNextPrayerDescription =>
      'الصلاة القادمة ووقتها والمدة المتبقية عليها.';

  @override
  String get widgetPrayerSchedule => 'مواقيت اليوم';

  @override
  String get widgetPrayerScheduleDescription =>
      'صلوات اليوم والشروق والوقت المتبقي للصلاة القادمة. عند تصغير الويدجت تظهر الصلوات القادمة. لو احتاج الوقت تحديثًا، اضغط للتحديث ثم اضغط لفتح المواقيت.';

  @override
  String get widgetScheduleSettings => 'إعدادات ويدجت المواقيت';

  @override
  String get widgetScheduleSettingsHint =>
      'تُطبّق على كل نسخ ويدجت مواقيت اليوم. يتكيّف المحتوى مع المساحة.';

  @override
  String get widgetScheduleLayout => 'المواقيت المعروضة';

  @override
  String get widgetScheduleAll => 'الجدول الكامل';

  @override
  String get widgetScheduleUpcoming => 'الصلوات الثلاث القادمة';

  @override
  String get widgetScheduleSunrise => 'إظهار الشروق';

  @override
  String get widgetScheduleSunriseHint =>
      'يظهر الشروق في جدول مواقيت اليوم الكامل.';

  @override
  String get widgetScheduleDate => 'إظهار التاريخ الميلادي والهجري';

  @override
  String get widgetScheduleCountdown => 'الوقت المتبقي للصلاة القادمة';

  @override
  String get widgetScheduleLargeText => 'خط أكبر';

  @override
  String get widgetScheduleLargeTextHint =>
      'قد تظهر صلوات أقل عندما لا تكفي المساحة.';

  @override
  String get widgetScheduleSaveFailed =>
      'تعذر حفظ إعدادات الويدجت. حاول مرة أخرى.';

  @override
  String get widgetTasbih => 'المسبحة';

  @override
  String get widgetTasbihReset => 'تصفير';

  @override
  String get widgetTasbihCount => 'أضف واحدة إلى عدّاد المسبحة';

  @override
  String get widgetTasbihDescription =>
      'اضغط على الرقم لإضافة تسبيحة، وعلى زر التصفير للبدء من جديد.';

  @override
  String get widgetDhikr => 'ذكر مقترح';

  @override
  String get widgetDhikrDescription =>
      'قائمة أذكار مقترحة وتقدمك فيها؛ اضغط لفتحها.';

  @override
  String get hintOfflineTitle => 'انتبه: المصحف يحتاج الإنترنت';

  @override
  String hintOfflineBody(String size) {
    return 'صفحات المصحف تُحمَّل من الإنترنت عند فتحها. الصفحات التي فتحتها مرة تبقى على جهازك وتعمل دون إنترنت، أما غيرها فلن يظهر بلا اتصال. نزّل المصحف كاملًا ($size م.ب) ليعمل في أي وقت ومكان.';
  }

  @override
  String hintOfflineAction(String name) {
    return 'نزّل مصحف $name كاملًا';
  }

  @override
  String get creditsPermissionPending => 'الإذن قيد الطلب';

  @override
  String get creditsLibraries => 'تراخيص المكتبات البرمجية';

  @override
  String get creditsIcons =>
      'الأيقونات: Material Icons من Google (رخصة Apache 2.0). أيقونة التطبيق ونجمة شاشة البدء من تصميم التطبيق نفسه.';

  @override
  String get creditsBrandFont =>
      'شعار «made by MRECode» على شاشة البدء: مرسوم بخطَّي Marcellus (براين بونيسلافسكي، Astigmatic) وCormorant Garamond المائل (مشروع Cormorant)، كلاهما برخصة SIL المفتوحة للخطوط 1.1، من Google Fonts.';

  @override
  String get creditsPrayer =>
      'تُحسب المواقيت على جهازك بمكتبة adhan (رخصة MIT)، والتاريخ الهجري بمكتبة hijri (رخصة BSD). البحث عن المدن بخدمة نظام جهازك، والخريطة من Google Maps. لا يُرسل موقعك إلى أي خادم لنا.';

  @override
  String creditsAudioVoice(
    String title,
    String credit,
    String source,
    String license,
  ) {
    return '$title: $credit. المصدر: $source. الترخيص: $license.';
  }

  @override
  String get creditsAudioDuaMishary =>
      'الدعاء بعد الأذان بصوت الشيخ مشاري العفاسي: من تسجيل الأذان نفسه على archive.org. الإذن قيد الطلب.';

  @override
  String get creditsAudioDuaShaarawy =>
      'الدعاء بعد الأذان بصوت الشيخ محمد متولي الشعراوي: archive.org (أدعية الشيخ الشعراوي، الملف الأول). الإذن قيد الطلب.';

  @override
  String get creditsAudioIntro =>
      'أُخذت التسجيلات من أرشيف الإنترنت (archive.org) ومن مستودع abodehq/Athan-MP3 على GitHub، ونُظّفت (حذف السكوت وضبط الصوت) دون تغيير القراءة. الإذن بها من أصحابها قيد الطلب.';

  @override
  String get creditsRiwayat =>
      'نصوص روايات ورش وقالون والدوري وشعبة وخطوطها: مجمع الملك فهد لطباعة المصحف الشريف (صفحة المطوّرين https://qurancomplex.gov.sa/techquran/dev/)، عبر نسخة github.com/thetruetruth/quran-data-kfgqpc ‏(commit 281dbbe). بشروط المجمع نفسها: للاستخدام الرقمي مع ذكر المصدر والإصدار.';

  @override
  String get sourcesDesign => 'الخطوط والأيقونات';

  @override
  String get sourcesPrayer => 'مواقيت الصلاة والقبلة';

  @override
  String get sourcesAudio => 'أصوات الأذان والدعاء';

  @override
  String get sourcesAdhkar => 'الأذكار والأدعية';

  @override
  String get sourcesMushaf => 'المصحف المطبوع والروايات';

  @override
  String get sourcesQuran => 'القرآن الكريم';

  @override
  String get sourcesIntro =>
      'كل ما في التطبيق من نصوص وخطوط وصفحات وأصوات، ومن أين جاء، وبأي شروط. يُتحقق من كل ملف ببصمته قبل استخدامه.';

  @override
  String get creditsTanzil =>
      'نص القرآن وبيانات الفهرس (السور والأجزاء وبدايات الصفحات): مشروع تنزيل، رخصة CC BY 3.0، https://tanzil.net. الملفات مضمَّنة دون تعديل ومعها إشعار حقوقها، ويُتحقق منها بالبصمة.';

  @override
  String get creditsImages =>
      'صفحات المصحف المطبوع: رسومها من النسخة الرقمية لمصحف المدينة النبوية (حفص، 1441هـ) لمجمع الملك فهد لطباعة المصحف الشريف، https://qurancomplex.gov.sa، وجميع حقوقها محفوظة للمجمع. الصيغة المتجهة ومواضع الآيات: مشروع Quran.ws ‏(quran-svg)، رخصة CC BY 4.0، https://quran.ws. تُنزَّل الصفحات عند الحاجة، ويُتحقق من كل ملف بالمجموع الاختباري قبل عرضه.';

  @override
  String get done => 'تم';

  @override
  String get exitTitle => 'إغلاق التطبيق؟';

  @override
  String get exitBody => 'مكانك في المصحف وتقدّمك في الأذكار محفوظان.';

  @override
  String get exitStay => 'البقاء';

  @override
  String get exitClose => 'إغلاق';

  @override
  String get back => 'رجوع';

  @override
  String get searchOptions => 'ابحث في الخيارات';

  @override
  String get noResults => 'لا توجد نتائج';

  @override
  String get selectOption => 'اختيار';

  @override
  String get duas => 'الأذكار';

  @override
  String get adhkarSuggested => 'المقترح الآن';

  @override
  String get adhkarSearchHint => 'ابحث في الأذكار بالاسم أو بالنص';

  @override
  String get adhkarSearchPrompt => 'اكتب اسمًا مثل «النوم» أو كلمات من الدعاء.';

  @override
  String get adhkarSearchLists => 'القوائم';

  @override
  String get adhkarSearchMatches => 'أذكار مطابقة';

  @override
  String get adhkarFavorites => 'المفضلة';

  @override
  String get adhkarSections => 'الأقسام';

  @override
  String get adhkarQuickAccess => 'وصول سريع';

  @override
  String get adhkarFavoriteAdd => 'أضِف إلى المفضلة';

  @override
  String get adhkarFavoriteRemove => 'أزِل من المفضلة';

  @override
  String adhkarListCount(String count) {
    return '$count قائمة';
  }

  @override
  String get adhkarPrayerSection => 'بعد كل صلاة';

  @override
  String get adhkarPrayerSwitch => 'ذكّرني بعد كل صلاة';

  @override
  String get adhkarPrayerSwitchHint =>
      'تُحسب مواقيت الصلاة على هاتفك من موقعك التقريبي. لا يُرسَل شيء إلى أي جهة.';

  @override
  String get adhkarPrayerMethod => 'طريقة الحساب';

  @override
  String get adhkarPrayerAfter => 'التذكير بعد الصلاة';

  @override
  String adhkarPrayerMinutes(String minutes) {
    return '$minutes دقيقة';
  }

  @override
  String get adhkarLocationDenied =>
      'الموقع متوقف لهذا التطبيق فلا يمكن حساب مواقيت الصلاة. اسمح به من إعدادات الجهاز.';

  @override
  String get adhkarPrayerReminderTitle => 'حان وقت أذكار بعد الصلاة';

  @override
  String adhkarPrayerReminderBody(String prayer) {
    return 'بعد صلاة $prayer. اضغط للقراءة.';
  }

  @override
  String get prayerFajr => 'الفجر';

  @override
  String get prayerDhuhr => 'الظهر';

  @override
  String get prayerAsr => 'العصر';

  @override
  String get prayerMaghrib => 'المغرب';

  @override
  String get prayerIsha => 'العشاء';

  @override
  String get methodEgyptian => 'الهيئة المصرية العامة للمساحة';

  @override
  String get methodMuslimWorldLeague => 'رابطة العالم الإسلامي';

  @override
  String get methodUmmAlQura => 'أم القرى، مكة المكرمة';

  @override
  String get methodKarachi => 'جامعة العلوم الإسلامية، كراتشي';

  @override
  String get methodNorthAmerica => 'الجمعية الإسلامية لأمريكا الشمالية';

  @override
  String get methodDubai => 'دبي';

  @override
  String get methodKuwait => 'الكويت';

  @override
  String get methodQatar => 'قطر';

  @override
  String get methodTurkey => 'تركيا (الديانة)';

  @override
  String get methodSingapore => 'سنغافورة';

  @override
  String get prayerTimesTitle => 'مواقيت الصلاة';

  @override
  String get prayerSunrise => 'الشروق';

  @override
  String get prayerNext => 'الصلاة القادمة';

  @override
  String prayerIn(String duration) {
    return 'بعد $duration';
  }

  @override
  String prayerDuration(String hours, String minutes) {
    return '$hours س $minutes د';
  }

  @override
  String prayerDurationMinutes(String minutes) {
    return '$minutes د';
  }

  @override
  String get prayerNoPlaceTitle => 'اعرف مواقيت الصلاة';

  @override
  String get prayerNoPlaceBody =>
      'اختر موقعك التقريبي أو الدقيق، أو حدده على الخريطة. تُحسب المواقيت على هاتفك.';

  @override
  String get prayerLocate => 'استخدم موقعي';

  @override
  String get prayerUpdateLocation => 'حدّث موقعي';

  @override
  String get prayerChooseMap => 'اختر موقعًا من الخريطة';

  @override
  String get prayerChooseMapHint => 'حدّد موقعك يدويًا من Google Maps';

  @override
  String get prayerMapTitle => 'اختر موقعك';

  @override
  String get prayerMapHint =>
      'حرّك الخريطة حتى يشير رأس العلامة إلى مكانك. تستخدم الخريطة والبحث الإنترنت؛ وزر موقعي يطلب إذن الموقع.';

  @override
  String get prayerMapCurrentLocation => 'استخدم موقعي الحالي';

  @override
  String get prayerMapSearchHint => 'ابحث عن مدينة أو عنوان';

  @override
  String get prayerMapSearch => 'ابحث عن المكان';

  @override
  String get prayerMapNoResults => 'لم نجد مكانًا بهذا الاسم.';

  @override
  String get prayerLocationUnavailable =>
      'تعذّر تحديد موقعك. تأكد من تشغيل الموقع ومنح الإذن، أو اختر مكانك على الخريطة.';

  @override
  String get prayerMapSave => 'استخدم هذا الموقع';

  @override
  String get prayerMapSelect => 'اضغط على الخريطة لتحديد موقع';

  @override
  String prayerPlaceLine(String latitude, String longitude) {
    return 'الإحداثيات: $latitude، $longitude';
  }

  @override
  String get prayerMethodAuto => 'تلقائي حسب مكانك';

  @override
  String prayerMethodAutoWith(String method) {
    return 'تلقائي: $method';
  }

  @override
  String get prayerAlertsTitle => 'تنبيه عند دخول الوقت';

  @override
  String get prayerAlertsAll => 'تنبيه للصلوات الخمس';

  @override
  String get prayerAlertsHint =>
      'إشعار عند دخول الوقت. إذا فعّلت إعدادات الأذان فسيُشغَّل الأذان تلقائيًا، وإلا فبصوت إشعارات هاتفك.';

  @override
  String get prayerAlertOn => 'التنبيه مفعّل';

  @override
  String get prayerAlertOff => 'التنبيه متوقف';

  @override
  String get prayerExactNote =>
      'قد يؤخّر أندرويد التنبيه بضع دقائق ما لم يُسمح بالمنبّهات الدقيقة.';

  @override
  String get prayerExactAllow => 'السماح بالتوقيت الدقيق';

  @override
  String prayerAlertTitle(String prayer) {
    return 'حان وقت صلاة $prayer';
  }

  @override
  String get prayerAlertBody => 'اضغط لعرض مواقيت الصلاة.';

  @override
  String get prayerChannelName => 'تنبيهات وقت الصلاة';

  @override
  String get prayerJumuah => 'الجمعة';

  @override
  String prayerSoonTitle(String prayer) {
    return 'اقتربت صلاة $prayer';
  }

  @override
  String prayerSoonBody(int count, String number) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'باقي $number دقيقة على الأذان',
      few: 'باقي $number دقائق على الأذان',
      two: 'باقي دقيقتان على الأذان',
      one: 'باقي دقيقة على الأذان',
    );
    return '$_temp0';
  }

  @override
  String get prayerSoonChannelName => 'تذكير قبل الصلاة';

  @override
  String get prayerSoonSwitch => 'تذكير قبل الصلاة';

  @override
  String get prayerSoonHint =>
      'إشعار قبل الأذان بوقت تختاره، للصلوات التي فعّلت تنبيهها.';

  @override
  String get prayerSoonMinutes => 'قبل الأذان بـ';

  @override
  String minutesCount(int count, String number) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$number دقيقة',
      few: '$number دقائق',
      two: 'دقيقتين',
      one: 'دقيقة',
    );
    return '$_temp0';
  }

  @override
  String get qiblaTitle => 'القبلة';

  @override
  String get shortcutPrayer => 'مواقيت الصلاة والأذان';

  @override
  String get shortcutAdhkar => 'الأذكار والأدعية';

  @override
  String get shortcutReader => 'متابعة القراءة';

  @override
  String get qiblaTileSubtitle => 'بوصلة تشير إلى الكعبة';

  @override
  String qiblaDirectionLine(String degrees, String direction) {
    return 'القبلة: $degrees° · $direction';
  }

  @override
  String qiblaSemantics(String degrees, String direction) {
    return 'بوصلة القبلة. القبلة على $degrees درجة من الشمال، ناحية $direction.';
  }

  @override
  String get qiblaAligned => 'أنت تواجه القبلة';

  @override
  String qiblaTurnRight(String degrees) {
    return 'در يمينًا $degrees°';
  }

  @override
  String qiblaTurnLeft(String degrees) {
    return 'در يسارًا $degrees°';
  }

  @override
  String get qiblaHintFlat =>
      'أمسك الهاتف أفقيًا وبعيدًا عن المعادن والسماعات والأغطية المغناطيسية.';

  @override
  String get qiblaHintCalibrate =>
      'إن اضطربت البوصلة فحرّك الهاتف على هيئة رقم 8 لمعايرتها.';

  @override
  String get adhanSuggestionTitle => 'فعّل تنبيهات الصلاة والأذان';

  @override
  String get adhanSuggestionBody =>
      'اضبط موقعك والصلوات التي تريد التنبيه لها، واختر صوت الأذان المناسب لك.';

  @override
  String get adhanSuggestionAction => 'إعداد مواقيت الصلاة';

  @override
  String get qiblaNoSensor =>
      'لا يوجد في هذا الجهاز حساس بوصلة. تُظهر البوصلة زاوية القبلة من الشمال: حدّد الشمال ببوصلة أو بالشمس ثم در بهذه الزاوية.';

  @override
  String get qiblaPlaceNote =>
      'تُحسب على هاتفك من موقعك التقريبي، ولا يُرسل شيء إلى أي جهة.';

  @override
  String get compassNorth => 'الشمال';

  @override
  String get compassNorthEast => 'الشمال الشرقي';

  @override
  String get compassEast => 'الشرق';

  @override
  String get compassSouthEast => 'الجنوب الشرقي';

  @override
  String get compassSouth => 'الجنوب';

  @override
  String get compassSouthWest => 'الجنوب الغربي';

  @override
  String get compassWest => 'الغرب';

  @override
  String get compassNorthWest => 'الشمال الغربي';

  @override
  String get compassLetterNorth => 'ش';

  @override
  String get compassLetterEast => 'ق';

  @override
  String get compassLetterSouth => 'ج';

  @override
  String get compassLetterWest => 'غ';

  @override
  String get hijriMonth1 => 'محرم';

  @override
  String get hijriMonth2 => 'صفر';

  @override
  String get hijriMonth3 => 'ربيع الأول';

  @override
  String get hijriMonth4 => 'ربيع الآخر';

  @override
  String get hijriMonth5 => 'جمادى الأولى';

  @override
  String get hijriMonth6 => 'جمادى الآخرة';

  @override
  String get hijriMonth7 => 'رجب';

  @override
  String get hijriMonth8 => 'شعبان';

  @override
  String get hijriMonth9 => 'رمضان';

  @override
  String get hijriMonth10 => 'شوال';

  @override
  String get hijriMonth11 => 'ذو القعدة';

  @override
  String get hijriMonth12 => 'ذو الحجة';

  @override
  String hijriDateLine(String day, String month, String year) {
    return '$day $month $year هـ';
  }

  @override
  String get prayerWidgetEmpty => 'افتح مصحفي لتحديث مواقيت الصلاة';

  @override
  String get adhanTitle => 'الأذان';

  @override
  String get adhanTileSubtitle => 'الصوت وطريقة عمل التنبيه';

  @override
  String get adhanSectionAlert => 'التنبيه';

  @override
  String get adhanPlaySwitch => 'تشغيل الأذان وقت الصلاة';

  @override
  String get adhanPlayHint =>
      'يبدأ من تلقاء نفسه مع إشعار يبقى ظاهرًا حتى توقفه، كأنه مكالمة.';

  @override
  String get adhanFlipSwitch => 'إيقاف الأذان عند قلب الهاتف';

  @override
  String get adhanFlipHint => 'ضع الشاشة على السطح ليسكت الصوت.';

  @override
  String get adhanAnnounceSwitch => 'إعلان الصلاة قبل الأذان';

  @override
  String get adhanAnnounceHint => '«حان الآن موعد أذان الظهر» ثم الأذان.';

  @override
  String get adhanDuaSwitch => 'الدعاء بعد الأذان';

  @override
  String get adhanDuaHint => '«اللهم رب هذه الدعوة التامة…» بعد انتهاء الأذان.';

  @override
  String get adhanDuaShaarawy => 'بصوت الشيخ محمد متولي الشعراوي';

  @override
  String get adhanDuaMishary => 'بصوت الشيخ مشاري العفاسي';

  @override
  String get adhanFajrVoices => 'أذان الفجر';

  @override
  String get adhanFajrVoicesHint =>
      'لصلاة الفجر أذانها الخاص، وفيه «الصلاة خير من النوم».';

  @override
  String get adhanTest => 'جرّب التنبيه الآن';

  @override
  String get adhanTestHint => 'يشغّل الصوت المختار ويُظهر الإشعار.';

  @override
  String get adhanTestTitle => 'تجربة: حان وقت الصلاة';

  @override
  String get adhanTestBody => 'هكذا سيظهر التنبيه. اضغط إيقاف لإنهائه.';

  @override
  String get adhanVoices => 'الأصوات';

  @override
  String get adhanVoicesHint =>
      'استمع قبل التنزيل. الصوت المنزَّل يعمل بدون إنترنت.';

  @override
  String get adhanListen => 'استماع';

  @override
  String get adhanStopListening => 'إيقاف الاستماع';

  @override
  String adhanDownload(String size) {
    return 'تنزيل ($size)';
  }

  @override
  String adhanDownloading(String percent) {
    return 'جارٍ التنزيل $percent';
  }

  @override
  String get adhanCancel => 'إلغاء';

  @override
  String get adhanDelete => 'حذف التنزيل';

  @override
  String get adhanUse => 'استخدام هذا الصوت';

  @override
  String get adhanInUse => 'قيد الاستخدام';

  @override
  String get adhanBuiltIn => 'مدمج';

  @override
  String adhanSizeMb(String size) {
    return '$size م.ب';
  }

  @override
  String get adhanInfo => 'المصدر والترخيص';

  @override
  String adhanCreditLine(String credit) {
    return 'النسبة: $credit';
  }

  @override
  String adhanLicenseLine(String license) {
    return 'الترخيص: $license';
  }

  @override
  String adhanSourceLine(String source) {
    return 'المصدر: $source';
  }

  @override
  String get adhanDownloadNetwork =>
      'تعذّر التنزيل. تحقق من الاتصال وأعد المحاولة.';

  @override
  String get adhanDownloadIntegrity => 'الملف ليس هو المتوقع فلم يُحفظ.';

  @override
  String get adhanDownloadBusy => 'الخادم مشغول الآن. أعد المحاولة بعد دقائق.';

  @override
  String get adhanCustomTitle => 'من هاتفك';

  @override
  String get adhanCustomHint =>
      'اختر تسجيل أذان لديك، كصوت مؤذن تحبه. يُنسخ داخل التطبيق ويبقى على هذا الهاتف. استخدم فقط تسجيلات يحق لك استخدامها.';

  @override
  String get adhanCustomChoose => 'اختيار ملف';

  @override
  String get adhanCustomReplace => 'اختيار ملف آخر';

  @override
  String adhanCustomTooLarge(String size) {
    return 'الملف كبير جدًا. اختر ملفًا أقل من $size م.ب.';
  }

  @override
  String get adhanUnsupported =>
      'على iPhone لا يسمح النظام لأي تطبيق بتشغيل صوت طويل من تلقاء نفسه. لذلك يرنّ مع إشعار وقت الصلاة أول ٣٠ ثانية من الأذان (وأذان الفجر في الفجر)، ويصل الإشعار حتى في وضع التركيز.';

  @override
  String get adhanLicenseNote =>
      'لا تتوفر هنا تسجيلات لمؤذنين مشهورين لأن أيًّا منها ليس مرخَّصًا للاستخدام الحر. كل صوت هنا مشارَك بالترخيص المذكور.';

  @override
  String get adhanStopAction => 'إيقاف الأذان';

  @override
  String get adhanChannelName => 'الأذان';

  @override
  String get settingsHaptics => 'الاهتزاز';

  @override
  String get settingsHapticsHint =>
      'نبضة خفيفة مع كل عدّة، وأقوى عند اكتمال الذكر.';

  @override
  String get settingsWidgetSeconds => 'الثواني في أداة المواقيت';

  @override
  String get settingsWidgetSecondsHint =>
      'تعدّ الأداة على الشاشة الرئيسية الوقت المتبقي بالثواني. تستهلك قليلًا من البطارية وهي ظاهرة.';

  @override
  String adhkarOnlyAfter(String prayers) {
    return 'بعد $prayers فقط';
  }

  @override
  String adhkarAnd(String first, String second) {
    return '$first و$second';
  }

  @override
  String adhkarStep(String step, String total) {
    return 'الخطوة $step من $total';
  }

  @override
  String get adhkarStepPrevious => 'السابق';

  @override
  String get adhkarStepNext => 'التالي';

  @override
  String get adhkarShowList => 'عرض كقائمة';

  @override
  String get settingsReading => 'القراءة';

  @override
  String get settingsAlerts => 'التنبيهات والاهتزاز';

  @override
  String get settingsHapticsUnsupported => 'هذا الجهاز لا يدعم الاهتزاز.';

  @override
  String get adhkarResume => 'أكمل من حيث توقفت';

  @override
  String adhkarNext(String title) {
    return 'التالي: $title';
  }

  @override
  String get adhkarStart => 'ابدأ';

  @override
  String get adhkarContinue => 'تابع';

  @override
  String get adhkarDoneToday => 'تمّ اليوم';

  @override
  String adhkarProgress(String done, String total) {
    return '$done من $total';
  }

  @override
  String adhkarCounterLabel(String done, String total) {
    return '$done من $total. اضغط للعدّ.';
  }

  @override
  String get adhkarUndo => 'تراجع عن مرة';

  @override
  String get adhkarResetEntry => 'إعادة هذا الذكر';

  @override
  String get adhkarEvidence => 'الدليل';

  @override
  String get adhkarSourceLabel => 'المصدر';

  @override
  String get adhkarQuranLabel => 'من القرآن';

  @override
  String get adhkarVirtueLabel => 'الفضل';

  @override
  String get adhkarHadithLabel => 'نص الحديث';

  @override
  String get adhkarVocabularyLabel => 'معاني الكلمات';

  @override
  String get adhkarCompleteTitle => 'تقبّل الله منك';

  @override
  String adhkarCompleteBody(String title) {
    return 'أتممت $title لليوم.';
  }

  @override
  String get adhkarRestart => 'ابدأ من جديد';

  @override
  String get adhkarLoadError => 'تعذّر تحميل الأذكار. حاول مرة أخرى.';

  @override
  String get adhkarReminders => 'التذكيرات';

  @override
  String get adhkarRemindersNone => 'لا يوجد تذكير مفعّل';

  @override
  String adhkarRemindersSome(String count) {
    return '$count مفعّل';
  }

  @override
  String get adhkarReminderTime => 'وقت التذكير';

  @override
  String get adhkarReminderBody => 'حان وقت أذكارك. اضغط للقراءة.';

  @override
  String get adhkarReminderChannel => 'تذكيرات الأذكار';

  @override
  String get adhkarPermissionDenied =>
      'الإشعارات متوقفة لهذا التطبيق. اسمح بها من إعدادات الجهاز لتصلك التذكيرات.';

  @override
  String get creditsAdhkar =>
      'الأذكار والأدعية: أذكار الصباح والمساء من قاعدة Seen Arabic (رخصة MIT)، https://github.com/Seen-Arabic/Morning-And-Evening-Adhkar-DB. باقي الأذكار مقتطعة من نصوص الأحاديث نفسها في نسخ hadith-api (المصدر مفتوح، The Unlicense)، https://github.com/fawazahmed0/hadith-api، مع تخريجها وحكم الألباني. ترتيب أبواب «حصن المسلم» للشيخ سعيد بن علي بن وهف القحطاني مأخوذ من فهرس rn0x/Adhkar-json، ولم يُنسخ نصه. الملفات مضمّنة ويُتحقق منها بالبصمة.';

  @override
  String get startup => 'عند فتح التطبيق';

  @override
  String get startupLastTab => 'آخر تبويب';

  @override
  String get startupMushaf => 'المصحف';

  @override
  String get quranIndex => 'الفهرس';

  @override
  String get indexSurahs => 'السور';

  @override
  String get indexJuz => 'الأجزاء';

  @override
  String get indexSearchHint => 'ابحث بالاسم أو الرقم';

  @override
  String get revelationMeccan => 'مكية';

  @override
  String get revelationMedinan => 'مدنية';

  @override
  String ayahCount(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$formatted آية',
      few: '$formatted آيات',
      two: 'آيتان',
      one: 'آية واحدة',
    );
    return '$_temp0';
  }

  @override
  String pageNumber(String page) {
    return 'صفحة $page';
  }

  @override
  String juzTitle(String number) {
    return 'الجزء $number';
  }

  @override
  String juzStartsAt(String surah, String ayah) {
    return 'يبدأ من $surah، الآية $ayah';
  }

  @override
  String get indexLoadError => 'تعذّر تحميل الفهرس.';

  @override
  String get searchQuran => 'ابحث في القرآن';

  @override
  String get searchQuranHint => 'سورة أو آية أو كلمات';

  @override
  String get searchGoTo => 'انتقال مباشر';

  @override
  String get searchTextResults => 'نتائج النص';

  @override
  String searchTextCount(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$formatted نتيجة',
      few: '$formatted نتائج',
      two: 'نتيجتان',
      one: 'نتيجة واحدة',
    );
    return '$_temp0';
  }

  @override
  String searchShowingFirst(String shown, String total) {
    return 'عرض أول $shown من $total';
  }

  @override
  String get searchPromptTitle => 'ابحث عن سورة أو آية أو كلمات';

  @override
  String get searchPromptBody =>
      'جرّب «٢:٢٥٥» أو «البقرة ٢٥٥» أو كلمات بدون تشكيل مثل «الحمد لله».';

  @override
  String get searchNoResultsTitle => 'لا توجد نتائج';

  @override
  String get searchNoResultsBody => 'تحقق من الكتابة أو جرّب كلمات أقل.';

  @override
  String get searchLoadError => 'تعذّر تحميل نص القرآن.';

  @override
  String ayahNumber(String number) {
    return 'آية $number';
  }

  @override
  String surahTitle(String name) {
    return 'سورة $name';
  }

  @override
  String get readerMenu => 'الفهرس';

  @override
  String get displayOptions => 'العرض';

  @override
  String get textSize => 'حجم الخط';

  @override
  String get readerLoadError => 'تعذّر تحميل المصحف.';

  @override
  String get readerProvisional =>
      'تخطيط مؤقت: الآيات موزعة على صفحات مصحف المدينة، وتقسيم الأسطر ليس مطابقًا بعد.';

  @override
  String get creditsQuranFont =>
      'خط القرآن: أميري قرآن، تصميم خالد حسني وسباستيان كوش، رخصة SIL المفتوحة للخطوط 1.1، https://github.com/aliftype/amiri.';

  @override
  String get creditsMushafScript =>
      'نص المصحف وخطه والتفسير الميسر: مجمع الملك فهد لطباعة المصحف الشريف بالمدينة المنورة (خط النص العثماني لرواية حفص، الإصدار 2.0، وبيانات التفسير الميسر، الإصدار 3)، https://qurancomplex.gov.sa. الملفات مضمّنة كما هي دون تعديل، ويُتحقق منها بالبصمة. يتيحها المجمع للاستخدام الرقمي مع ذكر المصدر، وجميع الحقوق محفوظة له.';

  @override
  String hizbTitle(String number) {
    return 'الحزب $number';
  }

  @override
  String get copyAyah => 'نسخ الآية';

  @override
  String get tafsirAction => 'التفسير';

  @override
  String get tafsirTitle => 'التفسير الميسر';

  @override
  String tafsirOfHafsAyah(String number) {
    return 'تفسير الآية $number بترقيم حفص';
  }

  @override
  String get tafsirCredit =>
      'التفسير الميسر لنخبة من أساتذة التفسير، من بيانات مجمع الملك فهد لطباعة المصحف الشريف (الإصدار 3). النص كما هو دون تعديل.';

  @override
  String get tafsirCopy => 'نسخ التفسير';

  @override
  String get tafsirCopied => 'تم نسخ التفسير';

  @override
  String get tafsirLoadError => 'تعذّر تحميل التفسير.';

  @override
  String get ayahCopied => 'تم نسخ الآية';

  @override
  String get shareAyah => 'مشاركة';

  @override
  String get shareAyahsTitle => 'مشاركة الآيات';

  @override
  String get shareAsText => 'مشاركة كنص';

  @override
  String get shareAsImage => 'مشاركة كصورة';

  @override
  String get printAyahs => 'طباعة الآيات';

  @override
  String get printFailed => 'تعذرت الطباعة. حاول مرة أخرى.';

  @override
  String get widgetPreviewIosHint =>
      'تعرض الصور تصميم أندرويد الافتراضي. على iPhone يتبع الويدجت إعداداتك ومظهر الشاشة الرئيسية.';

  @override
  String get copyText => 'نسخ';

  @override
  String get ayahsCopied => 'تم النسخ';

  @override
  String get shareFailed => 'تعذّرت المشاركة';

  @override
  String shareLimit(String count) {
    return 'حتى $count آية في المرة الواحدة';
  }

  @override
  String get shareFrom => 'من';

  @override
  String get shareTo => 'إلى';

  @override
  String get shareSurah => 'السورة';

  @override
  String get shareAyahField => 'الآية';

  @override
  String sharePicture(String index, String count) {
    return 'صورة $index من $count';
  }

  @override
  String surahAyah(String surah, String ayah) {
    return '$surah $ayah';
  }

  @override
  String get selectAyahs => 'تحديد أكثر من آية';

  @override
  String get selectionHint => 'اضغط على آخر آية تريدها، ولو في صفحة أخرى';

  @override
  String selectionCount(int count, String number) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$number آية',
      few: '$number آيات',
      two: 'آيتان',
      one: 'آية واحدة',
    );
    return '$_temp0';
  }

  @override
  String get cancelSelection => 'إلغاء التحديد';

  @override
  String selectionLimitReached(String count) {
    return 'هذا أقصى عدد في المرة الواحدة: $count آية';
  }

  @override
  String ayahRange(String first, String last) {
    return '$first–$last';
  }

  @override
  String pageRange(String first, String last) {
    return 'صفحة $first–$last';
  }

  @override
  String ayahShareReference(String surah, String ayahs, String page) {
    return '[$surah: $ayahs · $page]';
  }

  @override
  String get previousAyah => 'الآية السابقة';

  @override
  String get nextAyah => 'الآية التالية';

  @override
  String get addBookmark => 'إضافة علامة';

  @override
  String get removeBookmark => 'إزالة العلامة';

  @override
  String get bookmarkAdded => 'تمت إضافة العلامة';

  @override
  String get bookmarkRemoved => 'تمت إزالة العلامة';

  @override
  String get undo => 'تراجع';

  @override
  String get nextPage => 'الصفحة التالية';

  @override
  String get previousPage => 'الصفحة السابقة';

  @override
  String get realisticPageTurn => 'تقليب واقعي للصفحات';

  @override
  String get realisticPageTurnDescription =>
      'تنثني الصفحة وتنقلب كالورق. أوقفه لتنزلق الصفحات ببساطة.';

  @override
  String get readerMode => 'طريقة العرض';

  @override
  String get readerModeText => 'نص مكتوب';

  @override
  String get readerModePrinted => 'المصحف المطبوع';

  @override
  String get readerModeDescription =>
      'المصحف المطبوع يُنزَّل صفحة صفحة ويُحفظ على الجهاز.';

  @override
  String get readerPageLayout => 'تخطيط الصفحات';

  @override
  String get readerPageLayoutAuto => 'تلقائي';

  @override
  String get readerPageLayoutSingle => 'صفحة واحدة';

  @override
  String get readerPageLayoutSpread => 'صفحتان متقابلتان';

  @override
  String get surahFrame => 'إطار اسم السورة';

  @override
  String get surahFrameCartouche => 'مُدبَّب';

  @override
  String get surahFrameClassic => 'كلاسيكي';

  @override
  String get surahFrameArch => 'مُقوَّس';

  @override
  String get surahFrameMinimal => 'بسيط';

  @override
  String get readerLandscape => 'قراءة أفقية';

  @override
  String get readerPortrait => 'قراءة رأسية';

  @override
  String get printedPageError =>
      'تعذّر تحميل الصفحة. تأكد من الاتصال بالإنترنت.';

  @override
  String get printedPageOffline =>
      'لا يوجد اتصال بالإنترنت، وهذه الصفحة ليست على الجهاز بعد. حمّل المصحف من «المصحف دون اتصال» ليعمل بلا إنترنت.';

  @override
  String printedPageLabel(String number) {
    return 'الصفحة $number من المصحف المطبوع';
  }

  @override
  String get offlineMushaf => 'المصحف دون اتصال';

  @override
  String get offlineMushafIntro =>
      'نزّل صفحات المصحف المطبوع لتقرأه بلا إنترنت. يستمر التحميل حتى لو أغلقت التطبيق، ويُتحقق من كل صفحة قبل عرضها.';

  @override
  String packNotDownloaded(String size) {
    return 'غير محمّل · نحو $size ميجابايت';
  }

  @override
  String get packStateError => 'تعذّرت قراءة حالة التحميل';

  @override
  String get mushafEdition => 'الرواية';

  @override
  String get editionLimitedNote =>
      'نسخ الآية وتفسيرها وعلاماتها والبحث تعمل على رواية حفص. في الروايات الأخرى تُعرض صفحات المصحف فقط.';

  @override
  String get editionInUse => 'تُقرأ الآن';

  @override
  String get offlinePickHint =>
      'اضغط على رواية لتقرأ بها. تعمل دون تحميل ما دام الإنترنت متاحًا.';

  @override
  String get packChecking => 'جارٍ التحقق مما على الجهاز…';

  @override
  String packDownloading(String percent) {
    return 'جارٍ التحميل · $percent٪';
  }

  @override
  String packPartial(String percent) {
    return 'تحميل جزئي · $percent٪';
  }

  @override
  String get packReady => 'جاهز دون اتصال';

  @override
  String get packDownload => 'تحميل';

  @override
  String get packResume => 'متابعة';

  @override
  String get packCancel => 'إلغاء';

  @override
  String get packDelete => 'حذف';

  @override
  String packDownloadTitle(String name) {
    return 'تحميل $name؟';
  }

  @override
  String packDownloadBody(String size) {
    return 'يستهلك نحو $size ميجابايت من البيانات والتخزين. يكمل التحميل في الخلفية حتى بعد إغلاق التطبيق.';
  }

  @override
  String packDeleteTitle(String name) {
    return 'حذف $name؟';
  }

  @override
  String get packDeleteBody => 'ستحتاج إلى اتصال بالإنترنت لقراءته مرة أخرى.';

  @override
  String get packStartError =>
      'تعذّر بدء التحميل. تحقق من الاتصال وحاول مرة أخرى.';

  @override
  String packNotifyRunningTitle(String name) {
    return 'جارٍ تحميل $name';
  }

  @override
  String packNotifyCompleteTitle(String name) {
    return 'تم تحميل $name';
  }

  @override
  String get packNotifyCompleteBody => 'يعمل الآن دون اتصال.';

  @override
  String packNotifyErrorTitle(String name) {
    return 'تعذّر إكمال $name';
  }

  @override
  String get packNotifyErrorBody => 'افتح الإعدادات لمتابعة التحميل.';

  @override
  String packNotifyPausedTitle(String name) {
    return 'توقّف تحميل $name مؤقتًا';
  }

  @override
  String get packNotifyPausedBody => 'اضغط «متابعة» لإكماله.';

  @override
  String packInstallingProgress(String percent) {
    return 'جارٍ تجهيز الصفحات والتحقق منها · $percent٪';
  }

  @override
  String get nextSurah => 'السورة التالية';

  @override
  String get goToPage => 'الانتقال إلى صفحة';

  @override
  String get goToPageAction => 'انتقال';

  @override
  String get fineScrub => 'تمرير دقيق';

  @override
  String get scrubCancelHint => 'اسحب لأعلى للإلغاء';

  @override
  String get scrubCancelNow => 'ارفع إصبعك للإلغاء';

  @override
  String get scrubberOpen => 'تصفّح الصفحات';

  @override
  String get scrubberClose => 'إغلاق شريط الصفحات';

  @override
  String scrubberPlace(String surah, String juz) {
    return '$surah · $juz';
  }

  @override
  String pageOfTotal(String page, String total) {
    return 'صفحة $page من $total';
  }

  @override
  String get bookmarkPage => 'إضافة علامة للصفحة';

  @override
  String get removePageBookmark => 'إزالة علامة الصفحة';

  @override
  String get surahOrderCaption => 'الترتيب';

  @override
  String get packStorageInfo =>
      'تُحفظ المصاحف المحمّلة في مساحة التطبيق الخاصة وليست في الذاكرة المؤقتة، فلا يمسحها تنظيف الذاكرة المؤقتة. ولا تدخل في النسخ الاحتياطي، وتُزال عند حذفها من هنا أو عند حذف التطبيق.';

  @override
  String packOnDevice(String size) {
    return 'على الجهاز: $size ميجابايت';
  }

  @override
  String packDeleteWarnTitle(String name) {
    return 'حذف $name من هذا الجهاز؟';
  }

  @override
  String packDeleteWarnBody(String pages, String size) {
    return 'سيُحذف $pages ملف ($size ميجابايت) نهائيًا. لن يعمل المصحف المطبوع دون إنترنت حتى تحمّله من جديد.';
  }

  @override
  String get packDeleteAck => 'أفهم ذلك وأريد الحذف';

  @override
  String get packDeletePermanently => 'حذف نهائي';

  @override
  String get printedFallbackNotice =>
      'صفحة المصحف المطبوع غير متاحة الآن، فيُعرض النص.';
}
