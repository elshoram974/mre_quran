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

  /// No description provided for @readerPreparationTitle.
  ///
  /// In en, this message translates to:
  /// **'Verified reader preparation'**
  String get readerPreparationTitle;

  /// No description provided for @readerPreparationBody.
  ///
  /// In en, this message translates to:
  /// **'The Mushaf renderer will appear only after its text, page map, and font are verified together.'**
  String get readerPreparationBody;

  /// No description provided for @readerPreparationSource.
  ///
  /// In en, this message translates to:
  /// **'The selected text source is Tanzil Uthmani. It will remain unmodified and attributed in the app.'**
  String get readerPreparationSource;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search Quran'**
  String get searchHint;

  /// No description provided for @searchUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Search activates when the verified Quran index is available.'**
  String get searchUnavailable;

  /// No description provided for @noBookmarksTitle.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet'**
  String get noBookmarksTitle;

  /// No description provided for @noBookmarksBody.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks will be available after verified reader data is installed.'**
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

  /// No description provided for @settingsSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save settings. Try again.'**
  String get settingsSaveError;

  /// No description provided for @dataIntegrity.
  ///
  /// In en, this message translates to:
  /// **'Data integrity'**
  String get dataIntegrity;

  /// No description provided for @dataIntegrityBody.
  ///
  /// In en, this message translates to:
  /// **'No Quran text or page asset is bundled until the source, licence, and checksum are verified.'**
  String get dataIntegrityBody;

  /// No description provided for @compactLayout.
  ///
  /// In en, this message translates to:
  /// **'One-page reader'**
  String get compactLayout;

  /// No description provided for @expandedLayout.
  ///
  /// In en, this message translates to:
  /// **'Two-page reading spread'**
  String get expandedLayout;

  /// No description provided for @adaptiveBody.
  ///
  /// In en, this message translates to:
  /// **'Layout follows available space and safe areas, including split view and foldable poses.'**
  String get adaptiveBody;

  /// No description provided for @creditsTitle.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get creditsTitle;

  /// No description provided for @creditsTanzil.
  ///
  /// In en, this message translates to:
  /// **'Quran text: Tanzil Project, CC BY 3.0. The app will include attribution and a Tanzil link with every bundled copy.'**
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
