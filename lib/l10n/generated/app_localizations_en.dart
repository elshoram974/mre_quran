// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MRE Quran';

  @override
  String get reader => 'Mushaf';

  @override
  String get bookmarks => 'Bookmarks';

  @override
  String get settings => 'Settings';

  @override
  String get search => 'Search';

  @override
  String get noBookmarksTitle => 'No bookmarks yet';

  @override
  String get noBookmarksBody =>
      'Bookmarks will be available after verified reader data is installed.';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSepia => 'Sepia';

  @override
  String get language => 'Language';

  @override
  String get languageArabic => 'Arabic';

  @override
  String get languageEnglish => 'English';

  @override
  String get reduceMotion => 'Reduce motion';

  @override
  String get reduceMotionDescription => 'Keep interface motion minimal.';

  @override
  String get arabicDigits => 'Arabic-Indic digits';

  @override
  String get arabicDigitsDescription =>
      'Use Arabic-Indic digits in the interface.';

  @override
  String get privacy => 'Privacy';

  @override
  String get crashReports => 'Crash reports';

  @override
  String get crashReportsDescription =>
      'Share anonymous crash reports to help improve the app. Off by default.';

  @override
  String get about => 'About and credits';

  @override
  String get retry => 'Retry';

  @override
  String get settingsLoadError => 'Could not load settings. Try again.';

  @override
  String get creditsTitle => 'Credits';

  @override
  String get creditsTanzil =>
      'Quran text: Tanzil Project, CC BY 3.0. The app will include attribution and a Tanzil link with every bundled copy.';

  @override
  String get creditsFonts =>
      'Mushaf fonts and page layout: pending verified KFGQPC source and redistribution terms.';

  @override
  String get creditsImages =>
      'Images mode: not enabled. No page image has been downloaded or bundled.';

  @override
  String get back => 'Back';

  @override
  String get searchOptions => 'Search options';

  @override
  String get noResults => 'No results found';

  @override
  String get selectOption => 'Select';

  @override
  String get duas => 'Duas';

  @override
  String get duasEmptyTitle => 'Duas and adhkar';

  @override
  String get duasEmptyBody =>
      'Duas and adhkar will appear once a verified, licensed source is approved.';

  @override
  String get startup => 'On launch';

  @override
  String get startupLastTab => 'Last tab';

  @override
  String get startupMushaf => 'Mushaf';

  @override
  String get quranIndex => 'Index';

  @override
  String get indexSurahs => 'Surahs';

  @override
  String get indexJuz => 'Juz';

  @override
  String get indexSearchHint => 'Search by name or number';

  @override
  String get revelationMeccan => 'Meccan';

  @override
  String get revelationMedinan => 'Medinan';

  @override
  String ayahCount(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$formatted ayahs',
      one: '1 ayah',
    );
    return '$_temp0';
  }

  @override
  String pageNumber(String page) {
    return 'Page $page';
  }

  @override
  String juzTitle(String number) {
    return 'Juz $number';
  }

  @override
  String juzStartsAt(String surah, String ayah) {
    return 'Starts at $surah, ayah $ayah';
  }

  @override
  String get currentPosition => 'Current position';

  @override
  String currentPositionBody(String page, String surah) {
    return 'Page $page · $surah';
  }

  @override
  String get indexLoadError => 'The index could not be loaded.';

  @override
  String get readerInfo =>
      'The Mushaf pages will appear once their text, page map, and font are verified together. The index below already works.';
}
