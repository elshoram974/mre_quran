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
      'العلامات ستتاح بعد تثبيت بيانات القارئ الموثّقة.';

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
  String get currentPosition => 'الموضع الحالي';

  @override
  String currentPositionBody(String page, String surah) {
    return 'صفحة $page · $surah';
  }

  @override
  String get indexLoadError => 'تعذّر تحميل الفهرس.';

  @override
  String get readerInfo =>
      'ستظهر صفحات المصحف بعد التحقق معًا من نصها وخريطة صفحاتها وخطها. الفهرس يعمل من الآن.';
}
