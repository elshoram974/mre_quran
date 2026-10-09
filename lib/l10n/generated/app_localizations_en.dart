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
      'Press and hold an ayah in the Mushaf to bookmark it.';

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
      'Quran text and index data (surahs, juz, page starts): Tanzil Project, CC BY 3.0, https://tanzil.net. The files are bundled unmodified, with their copyright notice, and verified by checksum.';

  @override
  String get creditsFonts =>
      'Mushaf fonts and page layout: pending verified KFGQPC source and redistribution terms.';

  @override
  String get creditsImages =>
      'Images mode: not enabled. No page image has been downloaded or bundled.';

  @override
  String get done => 'Done';

  @override
  String get exitTitle => 'Close the app?';

  @override
  String get exitBody =>
      'Your place in the Mushaf and today\'s adhkar are saved.';

  @override
  String get exitStay => 'Stay';

  @override
  String get exitClose => 'Close';

  @override
  String get back => 'Back';

  @override
  String get searchOptions => 'Search options';

  @override
  String get noResults => 'No results found';

  @override
  String get selectOption => 'Select';

  @override
  String get duas => 'Adhkar';

  @override
  String get adhkarSuggested => 'Suggested now';

  @override
  String get adhkarSearchHint => 'Search adhkar by name or words';

  @override
  String get adhkarSearchPrompt =>
      'Type a name, like \"sleep\", or words from a dua.';

  @override
  String get adhkarSearchLists => 'Lists';

  @override
  String get adhkarSearchMatches => 'Matching adhkar';

  @override
  String get adhkarFavorites => 'Favourites';

  @override
  String get adhkarSections => 'Sections';

  @override
  String get adhkarFavoriteAdd => 'Add to favourites';

  @override
  String get adhkarFavoriteRemove => 'Remove from favourites';

  @override
  String adhkarListCount(String count) {
    return '$count lists';
  }

  @override
  String get adhkarPrayerSection => 'After each prayer';

  @override
  String get adhkarPrayerSwitch => 'Remind me after each prayer';

  @override
  String get adhkarPrayerSwitchHint =>
      'Prayer times are worked out on your phone from your approximate location. Nothing is sent anywhere.';

  @override
  String get adhkarPrayerMethod => 'Calculation method';

  @override
  String get adhkarPrayerAfter => 'Reminder after the prayer';

  @override
  String adhkarPrayerMinutes(String minutes) {
    return '$minutes minutes';
  }

  @override
  String get adhkarLocationDenied =>
      'Location is off for this app, so prayer times cannot be worked out. Allow it in the system settings.';

  @override
  String get adhkarPrayerReminderTitle => 'Time for adhkar after prayer';

  @override
  String adhkarPrayerReminderBody(String prayer) {
    return 'After the $prayer prayer. Tap to read.';
  }

  @override
  String get prayerFajr => 'Fajr';

  @override
  String get prayerDhuhr => 'Dhuhr';

  @override
  String get prayerAsr => 'Asr';

  @override
  String get prayerMaghrib => 'Maghrib';

  @override
  String get prayerIsha => 'Isha';

  @override
  String get methodEgyptian => 'Egyptian General Authority of Survey';

  @override
  String get methodMuslimWorldLeague => 'Muslim World League';

  @override
  String get methodUmmAlQura => 'Umm al-Qura, Makkah';

  @override
  String get methodKarachi => 'University of Islamic Sciences, Karachi';

  @override
  String get methodNorthAmerica => 'Islamic Society of North America';

  @override
  String get methodDubai => 'Dubai';

  @override
  String get methodKuwait => 'Kuwait';

  @override
  String get methodQatar => 'Qatar';

  @override
  String get methodTurkey => 'Turkey (Diyanet)';

  @override
  String get methodSingapore => 'Singapore';

  @override
  String get prayerTimesTitle => 'Prayer times';

  @override
  String get prayerSunrise => 'Sunrise';

  @override
  String get prayerNext => 'Next prayer';

  @override
  String prayerIn(String duration) {
    return 'in $duration';
  }

  @override
  String prayerDuration(String hours, String minutes) {
    return '$hours h $minutes min';
  }

  @override
  String prayerDurationMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String get prayerNoPlaceTitle => 'Find prayer times';

  @override
  String get prayerNoPlaceBody =>
      'Share your approximate location once. The times are worked out on your phone and nothing is sent anywhere.';

  @override
  String get prayerLocate => 'Use my location';

  @override
  String get prayerUpdateLocation => 'Update my location';

  @override
  String prayerPlaceLine(String latitude, String longitude) {
    return 'Approximate place: $latitude, $longitude';
  }

  @override
  String get prayerMethodAuto => 'Automatic for your place';

  @override
  String prayerMethodAutoWith(String method) {
    return 'Automatic: $method';
  }

  @override
  String get prayerAlertsTitle => 'Alert at prayer time';

  @override
  String get prayerAlertsAll => 'Alert for all five';

  @override
  String get prayerAlertsHint =>
      'A notification when the time comes. The adhan recording is added once a licensed one is approved; until then it uses your phone\'s notification sound.';

  @override
  String get prayerAlertOn => 'Alert on';

  @override
  String get prayerAlertOff => 'Alert off';

  @override
  String get prayerExactNote =>
      'Android may delay the alert by a few minutes unless exact alarms are allowed.';

  @override
  String get prayerExactAllow => 'Allow exact timing';

  @override
  String prayerAlertTitle(String prayer) {
    return 'Time for the $prayer prayer';
  }

  @override
  String get prayerAlertBody => 'Tap to see the prayer times.';

  @override
  String get prayerChannelName => 'Prayer time alerts';

  @override
  String get settingsHaptics => 'Vibration';

  @override
  String get settingsHapticsHint =>
      'A light tick for each count, a firmer one when a dhikr is done.';

  @override
  String adhkarOnlyAfter(String prayers) {
    return 'After $prayers only';
  }

  @override
  String adhkarAnd(String first, String second) {
    return '$first and $second';
  }

  @override
  String adhkarStep(String step, String total) {
    return 'Step $step of $total';
  }

  @override
  String get adhkarStepPrevious => 'Previous';

  @override
  String get adhkarStepNext => 'Next';

  @override
  String get adhkarShowList => 'Show as a list';

  @override
  String get settingsReading => 'Reading';

  @override
  String get settingsAlerts => 'Alerts and feedback';

  @override
  String get settingsHapticsUnsupported => 'This device cannot vibrate.';

  @override
  String get adhkarResume => 'Pick up where you left off';

  @override
  String adhkarNext(String title) {
    return 'Next: $title';
  }

  @override
  String get adhkarStart => 'Start';

  @override
  String get adhkarContinue => 'Continue';

  @override
  String get adhkarDoneToday => 'Done today';

  @override
  String adhkarProgress(String done, String total) {
    return '$done of $total';
  }

  @override
  String adhkarCounterLabel(String done, String total) {
    return '$done of $total. Tap to count.';
  }

  @override
  String get adhkarUndo => 'Undo one';

  @override
  String get adhkarEvidence => 'Evidence';

  @override
  String get adhkarSourceLabel => 'Source';

  @override
  String get adhkarQuranLabel => 'From the Quran';

  @override
  String get adhkarVirtueLabel => 'Virtue';

  @override
  String get adhkarHadithLabel => 'The hadith';

  @override
  String get adhkarVocabularyLabel => 'Word meanings';

  @override
  String get adhkarCompleteTitle => 'May Allah accept from you';

  @override
  String adhkarCompleteBody(String title) {
    return 'You finished $title for today.';
  }

  @override
  String get adhkarRestart => 'Start over';

  @override
  String get adhkarLoadError => 'Could not load the adhkar. Try again.';

  @override
  String get adhkarReminders => 'Reminders';

  @override
  String get adhkarRemindersNone => 'No reminder is on';

  @override
  String adhkarRemindersSome(String count) {
    return '$count on';
  }

  @override
  String get adhkarReminderTime => 'Reminder time';

  @override
  String get adhkarReminderBody => 'Time for your adhkar. Tap to read.';

  @override
  String get adhkarReminderChannel => 'Adhkar reminders';

  @override
  String get adhkarPermissionDenied =>
      'Notifications are off for this app. Allow them in the system settings to get reminders.';

  @override
  String get creditsAdhkar =>
      'Adhkar text, repeat counts, and evidence: the Morning and Evening Adhkar database by Seen Arabic (MIT), https://github.com/Seen-Arabic/Morning-And-Evening-Adhkar-DB, taken from the book Hisn al-Muslim by Sa\'id bin Ali bin Wahf al-Qahtani. Bundled unmodified and verified by checksum.';

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
  String get indexLoadError => 'The index could not be loaded.';

  @override
  String get searchQuran => 'Search the Quran';

  @override
  String get searchQuranHint => 'Surah, ayah, or words';

  @override
  String get searchGoTo => 'Go to';

  @override
  String get searchTextResults => 'Results in the text';

  @override
  String searchTextCount(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$formatted results',
      one: '1 result',
    );
    return '$_temp0';
  }

  @override
  String searchShowingFirst(String shown, String total) {
    return 'Showing the first $shown of $total';
  }

  @override
  String get searchPromptTitle => 'Find a surah, an ayah, or words';

  @override
  String get searchPromptBody =>
      'Try “2:255”, “Al-Baqara 255”, or words without tashkeel such as “الحمد لله”.';

  @override
  String get searchNoResultsTitle => 'Nothing matched';

  @override
  String get searchNoResultsBody => 'Check the spelling, or try fewer words.';

  @override
  String get searchLoadError => 'The Quran text could not be loaded.';

  @override
  String ayahNumber(String number) {
    return 'Ayah $number';
  }

  @override
  String surahTitle(String name) {
    return 'Surah $name';
  }

  @override
  String get readerMenu => 'Index';

  @override
  String get displayOptions => 'Display';

  @override
  String get textSize => 'Text size';

  @override
  String get readerLoadError => 'The Mushaf could not be loaded.';

  @override
  String get readerProvisional =>
      'Provisional layout: ayahs follow the Madinah pages, line breaks are not yet exact.';

  @override
  String get creditsQuranFont =>
      'Quran font: Amiri Quran by Khaled Hosny and Sebastian Kosch, SIL Open Font License 1.1, https://github.com/aliftype/amiri.';

  @override
  String hizbTitle(String number) {
    return 'Hizb $number';
  }

  @override
  String get copyAyah => 'Copy ayah';

  @override
  String get ayahCopied => 'Ayah copied';

  @override
  String get addBookmark => 'Add bookmark';

  @override
  String get removeBookmark => 'Remove bookmark';

  @override
  String get bookmarkAdded => 'Bookmark added';

  @override
  String get bookmarkRemoved => 'Bookmark removed';

  @override
  String get undo => 'Undo';

  @override
  String get nextPage => 'Next page';

  @override
  String get previousPage => 'Previous page';

  @override
  String get realisticPageTurn => 'Realistic page turning';

  @override
  String get realisticPageTurnDescription =>
      'Pages bend and turn like paper. Turn it off for a simple slide.';

  @override
  String get readerMode => 'Display';

  @override
  String get readerModeText => 'Typeset text';

  @override
  String get readerModePrinted => 'Printed Mushaf';

  @override
  String get readerModeDescription =>
      'The printed Mushaf downloads page by page and is kept on the device.';

  @override
  String get readerPageLayout => 'Page layout';

  @override
  String get readerPageLayoutAuto => 'Automatic';

  @override
  String get readerPageLayoutSingle => 'Single page';

  @override
  String get readerPageLayoutSpread => 'Two-page spread';

  @override
  String get readerLandscape => 'Landscape reading';

  @override
  String get readerPortrait => 'Portrait reading';

  @override
  String get printedPageError =>
      'Couldn\'t load this page. Check your internet connection.';

  @override
  String printedPageLabel(String number) {
    return 'Page $number of the printed Mushaf';
  }

  @override
  String get mushafStyle => 'Mushaf style';

  @override
  String get mushafStyleMadinah => 'Madinah Mushaf';

  @override
  String get mushafStyleTajweed => 'Tajweed Mushaf';

  @override
  String get mushafStyleMadinahHd => 'Madinah Mushaf, high resolution';

  @override
  String get offlineMushaf => 'Offline Mushaf';

  @override
  String get offlineMushafIntro =>
      'Download one or more editions to read without internet, then pick the one you want above. Downloads keep going when you close the app.';

  @override
  String packNotDownloaded(String size) {
    return 'Not downloaded · about $size MB';
  }

  @override
  String packDownloading(String percent) {
    return 'Downloading · $percent%';
  }

  @override
  String packPartial(String percent) {
    return 'Partly downloaded · $percent%';
  }

  @override
  String get packReady => 'Ready offline';

  @override
  String get packDownload => 'Download';

  @override
  String get packResume => 'Resume';

  @override
  String get packCancel => 'Cancel';

  @override
  String get packDelete => 'Delete';

  @override
  String packDownloadTitle(String name) {
    return 'Download $name?';
  }

  @override
  String packDownloadBody(String size) {
    return 'It takes about $size MB of data and storage. The download continues in the background, even after you close the app.';
  }

  @override
  String packDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get packDeleteBody =>
      'You will need an internet connection to read it again.';

  @override
  String get packStartError =>
      'Couldn\'t start the download. Check your internet connection and try again.';

  @override
  String packNotifyRunningTitle(String name) {
    return 'Downloading $name';
  }

  @override
  String packNotifyCompleteTitle(String name) {
    return '$name downloaded';
  }

  @override
  String get packNotifyCompleteBody => 'It now works without internet.';

  @override
  String packNotifyErrorTitle(String name) {
    return 'Couldn\'t finish $name';
  }

  @override
  String get packNotifyErrorBody => 'Open settings to continue the download.';

  @override
  String get nextSurah => 'Next surah';

  @override
  String get goToPage => 'Go to page';

  @override
  String get goToPageAction => 'Go';

  @override
  String pageOfTotal(String page, String total) {
    return 'Page $page of $total';
  }

  @override
  String get bookmarkPage => 'Bookmark this page';

  @override
  String get removePageBookmark => 'Remove this page\'s bookmark';

  @override
  String get hideBars => 'Hide the bars';

  @override
  String get surahOrderCaption => 'Order';

  @override
  String get surahAyahsCaption => 'Ayahs';

  @override
  String surahOrderLabel(String number) {
    return 'Order $number';
  }

  @override
  String get packStorageInfo =>
      'Downloaded Mushafs are kept in the app\'s own private storage, not in the cache, so clearing the cache does not remove them. They stay out of backups, and are removed when you delete them here or uninstall the app.';

  @override
  String packOnDevice(String size) {
    return 'On this device: $size MB';
  }

  @override
  String packDeleteWarnTitle(String name) {
    return 'Delete $name from this device?';
  }

  @override
  String packDeleteWarnBody(String pages, String size) {
    return '$pages page images ($size MB) will be deleted permanently. This edition will not work without internet until you download it again.';
  }

  @override
  String get packDeleteAck => 'I understand and want to delete it';

  @override
  String get packDeletePermanently => 'Delete permanently';

  @override
  String get editionsIntroTitle => 'More Mushafs to choose from';

  @override
  String get editionsIntroBody =>
      'You are reading the standard Madinah Mushaf. Other editions are available, such as the tajweed-coloured Mushaf. Pick the one you like, and download any of them to read without internet. You can change this later in Settings.';

  @override
  String get editionsIntroDone => 'Continue reading';

  @override
  String get printedFallbackNotice =>
      'The page image isn\'t available, so the text is shown.';
}
