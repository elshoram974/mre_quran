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

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @exitTitle.
  ///
  /// In en, this message translates to:
  /// **'Close the app?'**
  String get exitTitle;

  /// No description provided for @exitBody.
  ///
  /// In en, this message translates to:
  /// **'Your place in the Mushaf and today\'s adhkar are saved.'**
  String get exitBody;

  /// No description provided for @exitStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get exitStay;

  /// No description provided for @exitClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get exitClose;

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
  /// **'Adhkar'**
  String get duas;

  /// No description provided for @adhkarSuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested now'**
  String get adhkarSuggested;

  /// No description provided for @adhkarSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search adhkar by name or words'**
  String get adhkarSearchHint;

  /// No description provided for @adhkarSearchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Type a name, like \"sleep\", or words from a dua.'**
  String get adhkarSearchPrompt;

  /// No description provided for @adhkarSearchLists.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get adhkarSearchLists;

  /// No description provided for @adhkarSearchMatches.
  ///
  /// In en, this message translates to:
  /// **'Matching adhkar'**
  String get adhkarSearchMatches;

  /// No description provided for @adhkarFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get adhkarFavorites;

  /// No description provided for @adhkarSections.
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get adhkarSections;

  /// No description provided for @adhkarFavoriteAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to favourites'**
  String get adhkarFavoriteAdd;

  /// No description provided for @adhkarFavoriteRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from favourites'**
  String get adhkarFavoriteRemove;

  /// No description provided for @adhkarListCount.
  ///
  /// In en, this message translates to:
  /// **'{count} lists'**
  String adhkarListCount(String count);

  /// No description provided for @adhkarPrayerSection.
  ///
  /// In en, this message translates to:
  /// **'After each prayer'**
  String get adhkarPrayerSection;

  /// No description provided for @adhkarPrayerSwitch.
  ///
  /// In en, this message translates to:
  /// **'Remind me after each prayer'**
  String get adhkarPrayerSwitch;

  /// No description provided for @adhkarPrayerSwitchHint.
  ///
  /// In en, this message translates to:
  /// **'Prayer times are worked out on your phone from your approximate location. Nothing is sent anywhere.'**
  String get adhkarPrayerSwitchHint;

  /// No description provided for @adhkarPrayerMethod.
  ///
  /// In en, this message translates to:
  /// **'Calculation method'**
  String get adhkarPrayerMethod;

  /// No description provided for @adhkarPrayerAfter.
  ///
  /// In en, this message translates to:
  /// **'Reminder after the prayer'**
  String get adhkarPrayerAfter;

  /// No description provided for @adhkarPrayerMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String adhkarPrayerMinutes(String minutes);

  /// No description provided for @adhkarLocationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location is off for this app, so prayer times cannot be worked out. Allow it in the system settings.'**
  String get adhkarLocationDenied;

  /// No description provided for @adhkarPrayerReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Time for adhkar after prayer'**
  String get adhkarPrayerReminderTitle;

  /// No description provided for @adhkarPrayerReminderBody.
  ///
  /// In en, this message translates to:
  /// **'After the {prayer} prayer. Tap to read.'**
  String adhkarPrayerReminderBody(String prayer);

  /// No description provided for @prayerFajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get prayerFajr;

  /// No description provided for @prayerDhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get prayerDhuhr;

  /// No description provided for @prayerAsr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get prayerAsr;

  /// No description provided for @prayerMaghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get prayerMaghrib;

  /// No description provided for @prayerIsha.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get prayerIsha;

  /// No description provided for @methodEgyptian.
  ///
  /// In en, this message translates to:
  /// **'Egyptian General Authority of Survey'**
  String get methodEgyptian;

  /// No description provided for @methodMuslimWorldLeague.
  ///
  /// In en, this message translates to:
  /// **'Muslim World League'**
  String get methodMuslimWorldLeague;

  /// No description provided for @methodUmmAlQura.
  ///
  /// In en, this message translates to:
  /// **'Umm al-Qura, Makkah'**
  String get methodUmmAlQura;

  /// No description provided for @methodKarachi.
  ///
  /// In en, this message translates to:
  /// **'University of Islamic Sciences, Karachi'**
  String get methodKarachi;

  /// No description provided for @methodNorthAmerica.
  ///
  /// In en, this message translates to:
  /// **'Islamic Society of North America'**
  String get methodNorthAmerica;

  /// No description provided for @methodDubai.
  ///
  /// In en, this message translates to:
  /// **'Dubai'**
  String get methodDubai;

  /// No description provided for @methodKuwait.
  ///
  /// In en, this message translates to:
  /// **'Kuwait'**
  String get methodKuwait;

  /// No description provided for @methodQatar.
  ///
  /// In en, this message translates to:
  /// **'Qatar'**
  String get methodQatar;

  /// No description provided for @methodTurkey.
  ///
  /// In en, this message translates to:
  /// **'Turkey (Diyanet)'**
  String get methodTurkey;

  /// No description provided for @methodSingapore.
  ///
  /// In en, this message translates to:
  /// **'Singapore'**
  String get methodSingapore;

  /// No description provided for @prayerTimesTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer times'**
  String get prayerTimesTitle;

  /// No description provided for @prayerSunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get prayerSunrise;

  /// No description provided for @prayerNext.
  ///
  /// In en, this message translates to:
  /// **'Next prayer'**
  String get prayerNext;

  /// No description provided for @prayerIn.
  ///
  /// In en, this message translates to:
  /// **'in {duration}'**
  String prayerIn(String duration);

  /// No description provided for @prayerDuration.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String prayerDuration(String hours, String minutes);

  /// No description provided for @prayerDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String prayerDurationMinutes(String minutes);

  /// No description provided for @prayerNoPlaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Find prayer times'**
  String get prayerNoPlaceTitle;

  /// No description provided for @prayerNoPlaceBody.
  ///
  /// In en, this message translates to:
  /// **'Share your approximate location once. The times are worked out on your phone and nothing is sent anywhere.'**
  String get prayerNoPlaceBody;

  /// No description provided for @prayerLocate.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get prayerLocate;

  /// No description provided for @prayerUpdateLocation.
  ///
  /// In en, this message translates to:
  /// **'Update my location'**
  String get prayerUpdateLocation;

  /// No description provided for @prayerPlaceLine.
  ///
  /// In en, this message translates to:
  /// **'Approximate place: {latitude}, {longitude}'**
  String prayerPlaceLine(String latitude, String longitude);

  /// No description provided for @prayerMethodAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic for your place'**
  String get prayerMethodAuto;

  /// No description provided for @prayerMethodAutoWith.
  ///
  /// In en, this message translates to:
  /// **'Automatic: {method}'**
  String prayerMethodAutoWith(String method);

  /// No description provided for @prayerAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Alert at prayer time'**
  String get prayerAlertsTitle;

  /// No description provided for @prayerAlertsAll.
  ///
  /// In en, this message translates to:
  /// **'Alert for all five'**
  String get prayerAlertsAll;

  /// No description provided for @prayerAlertsHint.
  ///
  /// In en, this message translates to:
  /// **'A notification when the time comes. The adhan recording is added once a licensed one is approved; until then it uses your phone\'s notification sound.'**
  String get prayerAlertsHint;

  /// No description provided for @prayerAlertOn.
  ///
  /// In en, this message translates to:
  /// **'Alert on'**
  String get prayerAlertOn;

  /// No description provided for @prayerAlertOff.
  ///
  /// In en, this message translates to:
  /// **'Alert off'**
  String get prayerAlertOff;

  /// No description provided for @prayerExactNote.
  ///
  /// In en, this message translates to:
  /// **'Android may delay the alert by a few minutes unless exact alarms are allowed.'**
  String get prayerExactNote;

  /// No description provided for @prayerExactAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow exact timing'**
  String get prayerExactAllow;

  /// No description provided for @prayerAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Time for the {prayer} prayer'**
  String prayerAlertTitle(String prayer);

  /// No description provided for @prayerAlertBody.
  ///
  /// In en, this message translates to:
  /// **'Tap to see the prayer times.'**
  String get prayerAlertBody;

  /// No description provided for @prayerChannelName.
  ///
  /// In en, this message translates to:
  /// **'Prayer time alerts'**
  String get prayerChannelName;

  /// No description provided for @settingsHaptics.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get settingsHaptics;

  /// No description provided for @settingsHapticsHint.
  ///
  /// In en, this message translates to:
  /// **'A light tick for each count, a firmer one when a dhikr is done.'**
  String get settingsHapticsHint;

  /// No description provided for @adhkarOnlyAfter.
  ///
  /// In en, this message translates to:
  /// **'After {prayers} only'**
  String adhkarOnlyAfter(String prayers);

  /// No description provided for @adhkarAnd.
  ///
  /// In en, this message translates to:
  /// **'{first} and {second}'**
  String adhkarAnd(String first, String second);

  /// No description provided for @adhkarStep.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String adhkarStep(String step, String total);

  /// No description provided for @adhkarStepPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get adhkarStepPrevious;

  /// No description provided for @adhkarStepNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get adhkarStepNext;

  /// No description provided for @adhkarShowList.
  ///
  /// In en, this message translates to:
  /// **'Show as a list'**
  String get adhkarShowList;

  /// No description provided for @adhkarResume.
  ///
  /// In en, this message translates to:
  /// **'Pick up where you left off'**
  String get adhkarResume;

  /// No description provided for @adhkarNext.
  ///
  /// In en, this message translates to:
  /// **'Next: {title}'**
  String adhkarNext(String title);

  /// No description provided for @adhkarStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get adhkarStart;

  /// No description provided for @adhkarContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get adhkarContinue;

  /// No description provided for @adhkarDoneToday.
  ///
  /// In en, this message translates to:
  /// **'Done today'**
  String get adhkarDoneToday;

  /// No description provided for @adhkarProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String adhkarProgress(String done, String total);

  /// No description provided for @adhkarCounterLabel.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}. Tap to count.'**
  String adhkarCounterLabel(String done, String total);

  /// No description provided for @adhkarUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo one'**
  String get adhkarUndo;

  /// No description provided for @adhkarEvidence.
  ///
  /// In en, this message translates to:
  /// **'Evidence'**
  String get adhkarEvidence;

  /// No description provided for @adhkarSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get adhkarSourceLabel;

  /// No description provided for @adhkarQuranLabel.
  ///
  /// In en, this message translates to:
  /// **'From the Quran'**
  String get adhkarQuranLabel;

  /// No description provided for @adhkarVirtueLabel.
  ///
  /// In en, this message translates to:
  /// **'Virtue'**
  String get adhkarVirtueLabel;

  /// No description provided for @adhkarHadithLabel.
  ///
  /// In en, this message translates to:
  /// **'The hadith'**
  String get adhkarHadithLabel;

  /// No description provided for @adhkarVocabularyLabel.
  ///
  /// In en, this message translates to:
  /// **'Word meanings'**
  String get adhkarVocabularyLabel;

  /// No description provided for @adhkarCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'May Allah accept from you'**
  String get adhkarCompleteTitle;

  /// No description provided for @adhkarCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'You finished {title} for today.'**
  String adhkarCompleteBody(String title);

  /// No description provided for @adhkarRestart.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get adhkarRestart;

  /// No description provided for @adhkarLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the adhkar. Try again.'**
  String get adhkarLoadError;

  /// No description provided for @adhkarReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get adhkarReminders;

  /// No description provided for @adhkarRemindersNone.
  ///
  /// In en, this message translates to:
  /// **'No reminder is on'**
  String get adhkarRemindersNone;

  /// No description provided for @adhkarRemindersSome.
  ///
  /// In en, this message translates to:
  /// **'{count} on'**
  String adhkarRemindersSome(String count);

  /// No description provided for @adhkarReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get adhkarReminderTime;

  /// No description provided for @adhkarReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Time for your adhkar. Tap to read.'**
  String get adhkarReminderBody;

  /// No description provided for @adhkarReminderChannel.
  ///
  /// In en, this message translates to:
  /// **'Adhkar reminders'**
  String get adhkarReminderChannel;

  /// No description provided for @adhkarPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off for this app. Allow them in the system settings to get reminders.'**
  String get adhkarPermissionDenied;

  /// No description provided for @creditsAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Adhkar text, repeat counts, and evidence: the Morning and Evening Adhkar database by Seen Arabic (MIT), https://github.com/Seen-Arabic/Morning-And-Evening-Adhkar-DB, taken from the book Hisn al-Muslim by Sa\'id bin Ali bin Wahf al-Qahtani. Bundled unmodified and verified by checksum.'**
  String get creditsAdhkar;

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

  /// No description provided for @readerPageLayout.
  ///
  /// In en, this message translates to:
  /// **'Page layout'**
  String get readerPageLayout;

  /// No description provided for @readerPageLayoutAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get readerPageLayoutAuto;

  /// No description provided for @readerPageLayoutSingle.
  ///
  /// In en, this message translates to:
  /// **'Single page'**
  String get readerPageLayoutSingle;

  /// No description provided for @readerPageLayoutSpread.
  ///
  /// In en, this message translates to:
  /// **'Two-page spread'**
  String get readerPageLayoutSpread;

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

  /// No description provided for @offlineMushaf.
  ///
  /// In en, this message translates to:
  /// **'Offline Mushaf'**
  String get offlineMushaf;

  /// No description provided for @offlineMushafIntro.
  ///
  /// In en, this message translates to:
  /// **'Download one or more editions to read without internet, then pick the one you want above. Downloads keep going when you close the app.'**
  String get offlineMushafIntro;

  /// No description provided for @packNotDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Not downloaded · about {size} MB'**
  String packNotDownloaded(String size);

  /// No description provided for @packDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading · {percent}%'**
  String packDownloading(String percent);

  /// No description provided for @packPartial.
  ///
  /// In en, this message translates to:
  /// **'Partly downloaded · {percent}%'**
  String packPartial(String percent);

  /// No description provided for @packReady.
  ///
  /// In en, this message translates to:
  /// **'Ready offline'**
  String get packReady;

  /// No description provided for @packDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get packDownload;

  /// No description provided for @packResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get packResume;

  /// No description provided for @packCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get packCancel;

  /// No description provided for @packDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get packDelete;

  /// No description provided for @packDownloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Download {name}?'**
  String packDownloadTitle(String name);

  /// No description provided for @packDownloadBody.
  ///
  /// In en, this message translates to:
  /// **'It takes about {size} MB of data and storage. The download continues in the background, even after you close the app.'**
  String packDownloadBody(String size);

  /// No description provided for @packDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String packDeleteTitle(String name);

  /// No description provided for @packDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'You will need an internet connection to read it again.'**
  String get packDeleteBody;

  /// No description provided for @packStartError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start the download. Check your internet connection and try again.'**
  String get packStartError;

  /// No description provided for @packNotifyRunningTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloading {name}'**
  String packNotifyRunningTitle(String name);

  /// No description provided for @packNotifyCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} downloaded'**
  String packNotifyCompleteTitle(String name);

  /// No description provided for @packNotifyCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'It now works without internet.'**
  String get packNotifyCompleteBody;

  /// No description provided for @packNotifyErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t finish {name}'**
  String packNotifyErrorTitle(String name);

  /// No description provided for @packNotifyErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Open settings to continue the download.'**
  String get packNotifyErrorBody;

  /// No description provided for @nextSurah.
  ///
  /// In en, this message translates to:
  /// **'Next surah'**
  String get nextSurah;

  /// No description provided for @goToPage.
  ///
  /// In en, this message translates to:
  /// **'Go to page'**
  String get goToPage;

  /// No description provided for @goToPageAction.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get goToPageAction;

  /// No description provided for @pageOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {total}'**
  String pageOfTotal(String page, String total);

  /// No description provided for @bookmarkPage.
  ///
  /// In en, this message translates to:
  /// **'Bookmark this page'**
  String get bookmarkPage;

  /// No description provided for @removePageBookmark.
  ///
  /// In en, this message translates to:
  /// **'Remove this page\'s bookmark'**
  String get removePageBookmark;

  /// No description provided for @hideBars.
  ///
  /// In en, this message translates to:
  /// **'Hide the bars'**
  String get hideBars;

  /// No description provided for @surahOrderCaption.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get surahOrderCaption;

  /// No description provided for @surahAyahsCaption.
  ///
  /// In en, this message translates to:
  /// **'Ayahs'**
  String get surahAyahsCaption;

  /// No description provided for @surahOrderLabel.
  ///
  /// In en, this message translates to:
  /// **'Order {number}'**
  String surahOrderLabel(String number);

  /// No description provided for @packStorageInfo.
  ///
  /// In en, this message translates to:
  /// **'Downloaded Mushafs are kept in the app\'s own private storage, not in the cache, so clearing the cache does not remove them. They stay out of backups, and are removed when you delete them here or uninstall the app.'**
  String get packStorageInfo;

  /// No description provided for @packOnDevice.
  ///
  /// In en, this message translates to:
  /// **'On this device: {size} MB'**
  String packOnDevice(String size);

  /// No description provided for @packDeleteWarnTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name} from this device?'**
  String packDeleteWarnTitle(String name);

  /// No description provided for @packDeleteWarnBody.
  ///
  /// In en, this message translates to:
  /// **'{pages} page images ({size} MB) will be deleted permanently. This edition will not work without internet until you download it again.'**
  String packDeleteWarnBody(String pages, String size);

  /// No description provided for @packDeleteAck.
  ///
  /// In en, this message translates to:
  /// **'I understand and want to delete it'**
  String get packDeleteAck;

  /// No description provided for @packDeletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get packDeletePermanently;

  /// No description provided for @editionsIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'More Mushafs to choose from'**
  String get editionsIntroTitle;

  /// No description provided for @editionsIntroBody.
  ///
  /// In en, this message translates to:
  /// **'You are reading the standard Madinah Mushaf. Other editions are available, such as the tajweed-coloured Mushaf. Pick the one you like, and download any of them to read without internet. You can change this later in Settings.'**
  String get editionsIntroBody;

  /// No description provided for @editionsIntroDone.
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get editionsIntroDone;

  /// No description provided for @printedFallbackNotice.
  ///
  /// In en, this message translates to:
  /// **'The page image isn\'t available, so the text is shown.'**
  String get printedFallbackNotice;
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
