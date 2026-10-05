import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MRE Quran'**
  String get appTitle;

  /// No description provided for @reader.
  ///
  /// In en, this message translates to:
  /// **'Mushaf'**
  String get reader;

  /// No description provided for @bookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @noBookmarksTitle.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet'**
  String get noBookmarksTitle;

  /// No description provided for @noBookmarksBody.
  ///
  /// In en, this message translates to:
  /// **'Press and hold an ayah in the Mushaf to bookmark it.'**
  String get noBookmarksBody;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSepia.
  ///
  /// In en, this message translates to:
  /// **'Sepia'**
  String get themeSepia;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @reduceMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get reduceMotion;

  /// No description provided for @reduceMotionDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep interface motion minimal.'**
  String get reduceMotionDescription;

  /// No description provided for @arabicDigits.
  ///
  /// In en, this message translates to:
  /// **'Arabic-Indic digits'**
  String get arabicDigits;

  /// No description provided for @arabicDigitsDescription.
  ///
  /// In en, this message translates to:
  /// **'Use Arabic-Indic digits in the interface.'**
  String get arabicDigitsDescription;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @crashReports.
  ///
  /// In en, this message translates to:
  /// **'Crash reports'**
  String get crashReports;

  /// No description provided for @crashReportsDescription.
  ///
  /// In en, this message translates to:
  /// **'Share anonymous crash reports to help improve the app. Off by default.'**
  String get crashReportsDescription;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About and credits'**
  String get about;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @settingsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load settings. Try again.'**
  String get settingsLoadError;

  /// No description provided for @creditsTitle.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get creditsTitle;

  /// No description provided for @creditsTanzil.
  ///
  /// In en, this message translates to:
  /// **'Quran text and index data (surahs, juz, page starts): Tanzil Project, CC BY 3.0, https://tanzil.net. The files are bundled unmodified, with their copyright notice, and verified by checksum.'**
  String get creditsTanzil;

  /// No description provided for @creditsFonts.
  ///
  /// In en, this message translates to:
  /// **'Mushaf fonts and page layout: pending verified KFGQPC source and redistribution terms.'**
  String get creditsFonts;

  /// No description provided for @creditsImages.
  ///
  /// In en, this message translates to:
  /// **'Images mode: not enabled. No page image has been downloaded or bundled.'**
  String get creditsImages;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @searchOptions.
  ///
  /// In en, this message translates to:
  /// **'Search options'**
  String get searchOptions;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// No description provided for @selectOption.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectOption;

  /// No description provided for @duas.
  ///
  /// In en, this message translates to:
  /// **'Duas'**
  String get duas;

  /// No description provided for @duasEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Duas and adhkar'**
  String get duasEmptyTitle;

  /// No description provided for @duasEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Duas and adhkar will appear once a verified, licensed source is approved.'**
  String get duasEmptyBody;

  /// No description provided for @startup.
  ///
  /// In en, this message translates to:
  /// **'On launch'**
  String get startup;

  /// No description provided for @startupLastTab.
  ///
  /// In en, this message translates to:
  /// **'Last tab'**
  String get startupLastTab;

  /// No description provided for @startupMushaf.
  ///
  /// In en, this message translates to:
  /// **'Mushaf'**
  String get startupMushaf;

  /// No description provided for @quranIndex.
  ///
  /// In en, this message translates to:
  /// **'Index'**
  String get quranIndex;

  /// No description provided for @indexSurahs.
  ///
  /// In en, this message translates to:
  /// **'Surahs'**
  String get indexSurahs;

  /// No description provided for @indexJuz.
  ///
  /// In en, this message translates to:
  /// **'Juz'**
  String get indexJuz;

  /// No description provided for @indexSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or number'**
  String get indexSearchHint;

  /// No description provided for @revelationMeccan.
  ///
  /// In en, this message translates to:
  /// **'Meccan'**
  String get revelationMeccan;

  /// No description provided for @revelationMedinan.
  ///
  /// In en, this message translates to:
  /// **'Medinan'**
  String get revelationMedinan;

  /// No description provided for @ayahCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ayah} other{{formatted} ayahs}}'**
  String ayahCount(int count, String formatted);

  /// No description provided for @pageNumber.
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String pageNumber(String page);

  /// No description provided for @juzTitle.
  ///
  /// In en, this message translates to:
  /// **'Juz {number}'**
  String juzTitle(String number);

  /// No description provided for @juzStartsAt.
  ///
  /// In en, this message translates to:
  /// **'Starts at {surah}, ayah {ayah}'**
  String juzStartsAt(String surah, String ayah);

  /// No description provided for @indexLoadError.
  ///
  /// In en, this message translates to:
  /// **'The index could not be loaded.'**
  String get indexLoadError;

  /// No description provided for @searchQuran.
  ///
  /// In en, this message translates to:
  /// **'Search the Quran'**
  String get searchQuran;

  /// No description provided for @searchQuranHint.
  ///
  /// In en, this message translates to:
  /// **'Surah, ayah, or words'**
  String get searchQuranHint;

  /// No description provided for @searchGoTo.
  ///
  /// In en, this message translates to:
  /// **'Go to'**
  String get searchGoTo;

  /// No description provided for @searchTextResults.
  ///
  /// In en, this message translates to:
  /// **'Results in the text'**
  String get searchTextResults;

  /// No description provided for @searchTextCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 result} other{{formatted} results}}'**
  String searchTextCount(int count, String formatted);

  /// No description provided for @searchShowingFirst.
  ///
  /// In en, this message translates to:
  /// **'Showing the first {shown} of {total}'**
  String searchShowingFirst(String shown, String total);

  /// No description provided for @searchPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Find a surah, an ayah, or words'**
  String get searchPromptTitle;

  /// No description provided for @searchPromptBody.
  ///
  /// In en, this message translates to:
  /// **'Try “2:255”, “Al-Baqara 255”, or words without tashkeel such as “الحمد لله”.'**
  String get searchPromptBody;

  /// No description provided for @searchNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing matched'**
  String get searchNoResultsTitle;

  /// No description provided for @searchNoResultsBody.
  ///
  /// In en, this message translates to:
  /// **'Check the spelling, or try fewer words.'**
  String get searchNoResultsBody;

  /// No description provided for @searchLoadError.
  ///
  /// In en, this message translates to:
  /// **'The Quran text could not be loaded.'**
  String get searchLoadError;

  /// No description provided for @ayahNumber.
  ///
  /// In en, this message translates to:
  /// **'Ayah {number}'**
  String ayahNumber(String number);

  /// No description provided for @surahTitle.
  ///
  /// In en, this message translates to:
  /// **'Surah {name}'**
  String surahTitle(String name);

  /// No description provided for @readerMenu.
  ///
  /// In en, this message translates to:
  /// **'Index'**
  String get readerMenu;

  /// No description provided for @displayOptions.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get displayOptions;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSize;

  /// No description provided for @readerLoadError.
  ///
  /// In en, this message translates to:
  /// **'The Mushaf could not be loaded.'**
  String get readerLoadError;

  /// No description provided for @readerProvisional.
  ///
  /// In en, this message translates to:
  /// **'Provisional layout: ayahs follow the Madinah pages, line breaks are not yet exact.'**
  String get readerProvisional;

  /// No description provided for @creditsQuranFont.
  ///
  /// In en, this message translates to:
  /// **'Quran font: Amiri Quran by Khaled Hosny and Sebastian Kosch, SIL Open Font License 1.1, https://github.com/aliftype/amiri.'**
  String get creditsQuranFont;

  /// No description provided for @surahOrderLabel.
  ///
  /// In en, this message translates to:
  /// **'Order {number}'**
  String surahOrderLabel(String number);

  /// No description provided for @surahAyahsLabel.
  ///
  /// In en, this message translates to:
  /// **'Ayahs {count}'**
  String surahAyahsLabel(String count);

  /// No description provided for @hizbTitle.
  ///
  /// In en, this message translates to:
  /// **'Hizb {number}'**
  String hizbTitle(String number);

  /// No description provided for @copyAyah.
  ///
  /// In en, this message translates to:
  /// **'Copy ayah'**
  String get copyAyah;

  /// No description provided for @ayahCopied.
  ///
  /// In en, this message translates to:
  /// **'Ayah copied'**
  String get ayahCopied;

  /// No description provided for @addBookmark.
  ///
  /// In en, this message translates to:
  /// **'Add bookmark'**
  String get addBookmark;

  /// No description provided for @removeBookmark.
  ///
  /// In en, this message translates to:
  /// **'Remove bookmark'**
  String get removeBookmark;

  /// No description provided for @bookmarkAdded.
  ///
  /// In en, this message translates to:
  /// **'Bookmark added'**
  String get bookmarkAdded;

  /// No description provided for @bookmarkRemoved.
  ///
  /// In en, this message translates to:
  /// **'Bookmark removed'**
  String get bookmarkRemoved;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @nextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get nextPage;

  /// No description provided for @previousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get previousPage;

  /// No description provided for @realisticPageTurn.
  ///
  /// In en, this message translates to:
  /// **'Realistic page turning'**
  String get realisticPageTurn;

  /// No description provided for @realisticPageTurnDescription.
  ///
  /// In en, this message translates to:
  /// **'Pages bend and turn like paper. Turn it off for a simple slide.'**
  String get realisticPageTurnDescription;

  /// No description provided for @readerMode.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get readerMode;

  /// No description provided for @readerModeText.
  ///
  /// In en, this message translates to:
  /// **'Typeset text'**
  String get readerModeText;

  /// No description provided for @readerModePrinted.
  ///
  /// In en, this message translates to:
  /// **'Printed Mushaf'**
  String get readerModePrinted;

  /// No description provided for @readerModeDescription.
  ///
  /// In en, this message translates to:
  /// **'The printed Mushaf downloads page by page and is kept on the device.'**
  String get readerModeDescription;

  /// No description provided for @printedPageError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this page. Check your internet connection.'**
  String get printedPageError;

  /// No description provided for @printedPageLabel.
  ///
  /// In en, this message translates to:
  /// **'Page {number} of the printed Mushaf'**
  String printedPageLabel(String number);

  /// No description provided for @mushafStyle.
  ///
  /// In en, this message translates to:
  /// **'Mushaf style'**
  String get mushafStyle;

  /// No description provided for @mushafStyleMadinah.
  ///
  /// In en, this message translates to:
  /// **'Madinah Mushaf'**
  String get mushafStyleMadinah;

  /// No description provided for @mushafStyleTajweed.
  ///
  /// In en, this message translates to:
  /// **'Tajweed Mushaf'**
  String get mushafStyleTajweed;

  /// No description provided for @mushafStyleMadinahHd.
  ///
  /// In en, this message translates to:
  /// **'Madinah Mushaf, high resolution'**
  String get mushafStyleMadinahHd;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
