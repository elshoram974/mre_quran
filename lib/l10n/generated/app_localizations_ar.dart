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
  String get back => 'رجوع';

  @override
  String get searchOptions => 'ابحث في الخيارات';

  @override
  String get noResults => 'لا توجد نتائج';

  @override
  String get selectOption => 'اختيار';

  @override
  String get duas => 'الأدعية';

  @override
  String get duasEmptyTitle => 'الأدعية والأذكار';

  @override
  String get duasEmptyBody =>
      'ستظهر الأدعية والأذكار بعد اعتماد مصدر موثّق ومرخّص.';

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
  String surahOrderLabel(String number) {
    return 'ترتيبها $number';
  }

  @override
  String surahAyahsLabel(String count) {
    return 'آياتها $count';
  }

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
}
