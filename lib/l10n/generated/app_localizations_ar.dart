// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'مصحف MRE';

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
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeSepia => 'ورقي';

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
  String get crashReports => 'تقارير الأعطال';

  @override
  String get crashReportsDescription =>
      'أرسل تقارير أعطال مجهولة لتحسين التطبيق. متوقفة افتراضياً.';

  @override
  String get about => 'عن التطبيق والنسب';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get settingsLoadError => 'تعذّر تحميل الإعدادات. حاول مرة أخرى.';

  @override
  String get creditsTitle => 'النسب والمصادر';

  @override
  String get creditsTanzil =>
      'نص القرآن وبيانات الفهرس (السور والأجزاء وبدايات الصفحات): مشروع تنزيل، رخصة CC BY 3.0، https://tanzil.net. الملفات مضمَّنة دون تعديل ومعها إشعار حقوقها، ويُتحقق منها بالبصمة.';

  @override
  String get creditsFonts =>
      'خطوط المصحف وتخطيط الصفحات: في انتظار مصدر KFGQPC موثّق وشروط إعادة التوزيع.';

  @override
  String get creditsImages =>
      'وضع الصور: غير مفعّل. لم يتم تنزيل أو تضمين أي صورة صفحة.';

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
      'شارك موقعك التقريبي مرة واحدة. تُحسب المواقيت على هاتفك ولا يُرسَل شيء إلى أي جهة.';

  @override
  String get prayerLocate => 'استخدم موقعي';

  @override
  String get prayerUpdateLocation => 'حدّث موقعي';

  @override
  String prayerPlaceLine(String latitude, String longitude) {
    return 'المكان التقريبي: $latitude، $longitude';
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
      'إشعار عند دخول الوقت. يُضاف تسجيل الأذان بعد اعتماد تسجيل مرخّص، وحتى ذلك الحين يستخدم صوت إشعارات هاتفك.';

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
  String get qiblaTitle => 'القبلة';

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
      'إن اضطربت البوصلة فحرّك الهاتف على هيئة رقم ٨ لمعايرتها.';

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
  String get prayerWidgetEmpty => 'افتح مصحف MRE لتحديد موقعك';

  @override
  String get settingsHaptics => 'الاهتزاز';

  @override
  String get settingsHapticsHint =>
      'نبضة خفيفة مع كل عدّة، وأقوى عند اكتمال الذكر.';

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
      'نص الأذكار وعدد تكرارها وأدلتها: قاعدة بيانات أذكار الصباح والمساء من Seen Arabic (ترخيص MIT)، https://github.com/Seen-Arabic/Morning-And-Evening-Adhkar-DB، المأخوذة من كتاب «حصن المسلم» للشيخ سعيد بن علي بن وهف القحطاني. مضمّنة دون تعديل ومتحقَّق منها بالبصمة.';

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
  String hizbTitle(String number) {
    return 'الحزب $number';
  }

  @override
  String get copyAyah => 'نسخ الآية';

  @override
  String get ayahCopied => 'تم نسخ الآية';

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
  String get readerLandscape => 'قراءة أفقية';

  @override
  String get readerPortrait => 'قراءة رأسية';

  @override
  String get printedPageError =>
      'تعذّر تحميل الصفحة. تأكد من الاتصال بالإنترنت.';

  @override
  String printedPageLabel(String number) {
    return 'الصفحة $number من المصحف المطبوع';
  }

  @override
  String get mushafStyle => 'شكل المصحف';

  @override
  String get mushafStyleMadinah => 'مصحف المدينة';

  @override
  String get mushafStyleTajweed => 'مصحف التجويد';

  @override
  String get mushafStyleMadinahHd => 'مصحف المدينة عالي الدقة';

  @override
  String get offlineMushaf => 'المصحف دون اتصال';

  @override
  String get offlineMushafIntro =>
      'نزّل نسخة أو أكثر لتقرأ بلا إنترنت، ثم اختر النسخة التي تريدها من الأعلى. يستمر التحميل حتى لو أغلقت التطبيق.';

  @override
  String packNotDownloaded(String size) {
    return 'غير محمّل · نحو $size ميجابايت';
  }

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
  String get nextSurah => 'السورة التالية';

  @override
  String get goToPage => 'الانتقال إلى صفحة';

  @override
  String get goToPageAction => 'انتقال';

  @override
  String pageOfTotal(String page, String total) {
    return 'صفحة $page من $total';
  }

  @override
  String get bookmarkPage => 'إضافة علامة للصفحة';

  @override
  String get removePageBookmark => 'إزالة علامة الصفحة';

  @override
  String get hideBars => 'إخفاء الأشرطة';

  @override
  String get surahOrderCaption => 'الترتيب';

  @override
  String get surahAyahsCaption => 'آيات';

  @override
  String surahOrderLabel(String number) {
    return 'ترتيبها $number';
  }

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
    return 'سيُحذف $pages ملف صورة ($size ميجابايت) نهائيًا. لن تعمل هذه النسخة دون إنترنت حتى تحمّلها من جديد.';
  }

  @override
  String get packDeleteAck => 'أفهم ذلك وأريد الحذف';

  @override
  String get packDeletePermanently => 'حذف نهائي';

  @override
  String get editionsIntroTitle => 'مصاحف متنوعة بين يديك';

  @override
  String get editionsIntroBody =>
      'أنت تقرأ الآن مصحف المدينة المعتاد. وتوجد نسخ أخرى، مثل مصحف التجويد الملوّن. اختر ما يناسبك، ونزّل ما تشاء منها لتقرأ دون إنترنت. ويمكنك تغيير ذلك لاحقًا من الإعدادات.';

  @override
  String get editionsIntroDone => 'متابعة القراءة';

  @override
  String get printedFallbackNotice =>
      'صورة الصفحة غير متاحة الآن، فيُعرض النص.';
}
