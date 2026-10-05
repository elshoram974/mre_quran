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
  String get readerPreparationTitle => 'تجهيز قارئ موثّق';

  @override
  String get readerPreparationBody =>
      'هيظهر المصحف فقط بعد التحقق معًا من النص وخريطة الصفحات والخط.';

  @override
  String get readerPreparationSource =>
      'مصدر النص المختار هو تنـزيل العثماني. سيبقى بلا تعديل مع نسبته داخل التطبيق.';

  @override
  String get search => 'بحث';

  @override
  String get searchHint => 'ابحث في القرآن';

  @override
  String get searchUnavailable => 'البحث سيتفعّل بعد توفر فهرس القرآن الموثّق.';

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
      'متوقفة حتى يتوفر مشروع Firebase وموافقة صريحة.';

  @override
  String get about => 'عن التطبيق والنسب';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get settingsLoadError => 'تعذّر تحميل الإعدادات. حاول مرة أخرى.';

  @override
  String get settingsSaveError => 'تعذّر حفظ الإعدادات. حاول مرة أخرى.';

  @override
  String get dataIntegrity => 'سلامة البيانات';

  @override
  String get dataIntegrityBody =>
      'لن يُضمّن نص قرآن أو أصل صفحة قبل التحقق من المصدر والرخصة والبصمة.';

  @override
  String get compactLayout => 'قارئ بصفحة واحدة';

  @override
  String get expandedLayout => 'عرض قرائي بصفحتين';

  @override
  String get adaptiveBody =>
      'التخطيط يتبع المساحة المتاحة والمناطق الآمنة، بما فيها Split View وأوضاع الأجهزة القابلة للطي.';

  @override
  String get creditsTitle => 'النسب والمصادر';

  @override
  String get creditsTanzil =>
      'نص القرآن: مشروع تنـزيل، CC BY 3.0. سيحتوي التطبيق على النسبة ورابط تنـزيل مع كل نسخة مضمّنة.';

  @override
  String get creditsFonts =>
      'خطوط المصحف وتخطيط الصفحات: في انتظار مصدر KFGQPC موثّق وشروط إعادة التوزيع.';

  @override
  String get creditsImages =>
      'وضع الصور: غير مفعّل. لم يتم تنزيل أو تضمين أي صورة صفحة.';

  @override
  String get back => 'رجوع';
}
