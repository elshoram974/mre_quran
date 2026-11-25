// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mushafi';

  @override
  String get reader => 'Mushaf';

  @override
  String get prayerTab => 'Adhan';

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
  String get themeLight => 'Cream';

  @override
  String get themeDark => 'Navy';

  @override
  String get themeSepia => 'Sepia';

  @override
  String get themeWhite => 'White';

  @override
  String get themeGreen => 'Green';

  @override
  String get themeBlack => 'Black';

  @override
  String get pageTheme => 'Page colour';

  @override
  String get accentColor => 'Accent colour';

  @override
  String get accentColorHint => 'For ayah numbers, highlights, and buttons';

  @override
  String get accentGold => 'Gold';

  @override
  String get accentEmerald => 'Emerald';

  @override
  String get accentTeal => 'Teal';

  @override
  String get accentBlue => 'Blue';

  @override
  String get accentIndigo => 'Indigo';

  @override
  String get accentRose => 'Rose';

  @override
  String get accentCrimson => 'Crimson';

  @override
  String get accentBrown => 'Brown';

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
  String get privacyPolicy => 'Privacy policy';

  @override
  String get privacyPolicyDescription =>
      'What the app keeps, what it sends, and why';

  @override
  String get crashReports => 'Crash reports';

  @override
  String get crashReportsDescription =>
      'Technical crash reports, with none of your personal data, are sent so we can fix bugs quickly. You can turn them off.';

  @override
  String get about => 'About and credits';

  @override
  String get retry => 'Retry';

  @override
  String get settingsLoadError => 'Could not load settings. Try again.';

  @override
  String get creditsTitle => 'Credits';

  @override
  String get contactUs => 'Contact us';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactEmail => 'Email';

  @override
  String get contactFailed => 'Nothing on this device can open that.';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get hintNever => 'Don\'t remind me again';

  @override
  String get hintLater => 'Later';

  @override
  String get hintPermissionsTitle => 'We will ask for two permissions';

  @override
  String get hintPermissionsBody =>
      'Prayer alerts need notification permission and a location. You can choose approximate or precise location, or select a place on the map. Times are calculated on your device.';

  @override
  String get hintPermissionsAction => 'Continue';

  @override
  String get hintTryAdhanTitle => 'Try the adhan now';

  @override
  String get hintTryAdhanBody =>
      'Hear the alert as it will come at prayer time, and check that the sound is loud enough, before the first prayer.';

  @override
  String get hintTryAdhanAction => 'Try it now';

  @override
  String get hintWidgetsTitle => 'Prayer times on your home screen';

  @override
  String get hintWidgetsBody =>
      'Put the prayer times, a tasbih or a dhikr on your home screen, to see them without opening the app.';

  @override
  String get hintWidgetsAction => 'Choose a widget';

  @override
  String get hintWidgetsManual =>
      'Touch and hold the home screen, tap Widgets, and search for Mushafi.';

  @override
  String get widgetsTitle => 'Home-screen widgets';

  @override
  String get widgetsIntro =>
      'See prayer times, count tasbih and follow your adhkar from the home screen.';

  @override
  String get widgetsPreviewHint =>
      'Previews show the default design. Your choices apply to the widgets on your home screen.';

  @override
  String get widgetAppearance => 'Widget colours';

  @override
  String get widgetDefaultStyle => 'Original widget colours';

  @override
  String get widgetStyleSaveFailed =>
      'Could not save the widget colour. Try again.';

  @override
  String get widgetSizeSmall => 'Minimum Android size: two columns by one row.';

  @override
  String get widgetSizeTall =>
      'Recommended Android size: two columns by two rows; resizable.';

  @override
  String get widgetSizeWide =>
      'Minimum Android size: three columns by two rows.';

  @override
  String get widgetIosTasbihHint =>
      'Counting in the widget requires iOS 17 or later.';

  @override
  String get widgetsAdd => 'Add';

  @override
  String get widgetsAddAsked =>
      'Confirm on the screen that appears to place the widget.';

  @override
  String get widgetsStepsIos =>
      'To add a widget: touch and hold an empty spot on the home screen, tap + at the top, search for Mushafi, choose the widget and its size, then tap Add Widget.';

  @override
  String get widgetPrayerCard => 'Prayer card';

  @override
  String get widgetPrayerCardDescription =>
      'The next prayer and countdown, today\'s prayers, sunrise and date.';

  @override
  String get widgetNextPrayer => 'Next prayer';

  @override
  String get widgetNextPrayerDescription =>
      'The next prayer, its time and how long until it.';

  @override
  String get widgetPrayerSchedule => 'Today\'s prayer times';

  @override
  String get widgetPrayerScheduleDescription =>
      'Today\'s prayers, sunrise and the time until the next prayer. Smaller sizes show upcoming prayers. When the time needs refreshing, tap to update, then tap to open prayer times.';

  @override
  String get widgetScheduleSettings => 'Prayer times widget settings';

  @override
  String get widgetScheduleSettingsHint =>
      'Applies to all copies of the prayer times widget. Content adapts to the available space.';

  @override
  String get widgetScheduleLayout => 'Times shown';

  @override
  String get widgetScheduleAll => 'Full schedule';

  @override
  String get widgetScheduleUpcoming => 'Next three prayers';

  @override
  String get widgetScheduleSunrise => 'Show sunrise';

  @override
  String get widgetScheduleSunriseHint =>
      'Sunrise is shown in the full daily schedule.';

  @override
  String get widgetScheduleDate => 'Show Gregorian and Hijri dates';

  @override
  String get widgetScheduleCountdown => 'Time until the next prayer';

  @override
  String get widgetScheduleLargeText => 'Larger text';

  @override
  String get widgetScheduleLargeTextHint =>
      'Fewer prayers may be shown when space is limited.';

  @override
  String get widgetScheduleSaveFailed =>
      'Could not save widget settings. Try again.';

  @override
  String get widgetPreviewAdhkarTitle => 'Morning adhkar';

  @override
  String get widgetsGeneral => 'Settings for all widgets';

  @override
  String get widgetsEach => 'Each widget and its settings';

  @override
  String get widgetLanguage => 'Widgets language';

  @override
  String get widgetLanguageSameAsApp => 'Same as the app';

  @override
  String get widgetLanguageHint =>
      'Changes the widgets\' words, dates and clock, and updates them on the home screen at once.';

  @override
  String get widgetTasbih => 'Tasbih';

  @override
  String get widgetTasbihReset => 'Reset';

  @override
  String get widgetTasbihCount => 'Add one to the tasbih count';

  @override
  String get widgetTasbihDescription =>
      'Tap the number to add one, or reset to start again.';

  @override
  String get widgetDhikr => 'Suggested dhikr';

  @override
  String get widgetDhikrDescription =>
      'A suggested adhkar list and your progress; tap to open it.';

  @override
  String get hintOfflineTitle =>
      'The Mushaf needs the internet, just the first time';

  @override
  String hintOfflineBody(String size) {
    return 'Every page you open is saved on your phone, and opens later without the internet. You can also download the whole Mushaf once ($size MB), or read it as text, which never needs the internet.';
  }

  @override
  String get hintOfflineText => 'Read as text, no internet needed';

  @override
  String get hintGotIt => 'OK, got it';

  @override
  String hintOfflineAction(String name) {
    return 'Download the whole $name Mushaf';
  }

  @override
  String get creditsPermissionPending => 'Permission being asked for';

  @override
  String get creditsLibraries => 'Licences of the software libraries';

  @override
  String get creditsIcons =>
      'Icons: Material Icons by Google (Apache License 2.0). The app icon and the launch star are the app\'s own design.';

  @override
  String get creditsBrandFont =>
      'The \"made by MRECode\" mark on the launch screen: drawn in Marcellus (Brian J. Bonislawsky, Astigmatic) and Cormorant Garamond Italic (the Cormorant Project), both SIL Open Font License 1.1, from Google Fonts.';

  @override
  String get creditsPrayer =>
      'Times are worked out on your device with the adhan library (MIT licence), and the Hijri date with the hijri library (BSD licence). Cities are found by your device\'s own service, and the map is Google Maps. Your location is never sent to any server of ours.';

  @override
  String creditsAudioVoice(
    String title,
    String credit,
    String source,
    String license,
  ) {
    return '$title: $credit. Source: $source. Licence: $license.';
  }

  @override
  String get creditsAudioDuaMishary =>
      'The dua after the adhan by Sheikh Mishary Alafasy: from his adhan recording on archive.org. Permission is being asked for.';

  @override
  String get creditsAudioDuaShaarawy =>
      'The dua after the adhan by Sheikh Muhammad Metwalli Al-Shaarawy: archive.org (Sheikh Al-Shaarawy\'s duas, first file). Permission is being asked for.';

  @override
  String get creditsAudioIntro =>
      'The recordings come from the Internet Archive (archive.org) and the abodehq/Athan-MP3 repository on GitHub, cleaned (silence removed, loudness evened) without changing the recitation. Permission from their owners is being asked for.';

  @override
  String get creditsRiwayat =>
      'Texts and fonts of the readings of Warsh, Qalun, Al-Duri and Shu\'bah: King Fahd Glorious Quran Printing Complex (developer page https://qurancomplex.gov.sa/techquran/dev/), through the copy at github.com/thetruetruth/quran-data-kfgqpc (commit 281dbbe). On the Complex\'s own terms: digital use, with credit and version.';

  @override
  String get sourcesDesign => 'Fonts and icons';

  @override
  String get sourcesPrayer => 'Prayer times and the Qibla';

  @override
  String get sourcesAudio => 'Adhan and dua recordings';

  @override
  String get sourcesAdhkar => 'Adhkar and duas';

  @override
  String get sourcesMushaf => 'Printed Mushaf and the readings';

  @override
  String get sourcesQuran => 'The Quran';

  @override
  String get sourcesIntro =>
      'Every text, font, page and sound in the app: where it comes from, and on what terms. Every file is checked against its checksum before it is used.';

  @override
  String get creditsTanzil =>
      'Quran text and index data (surahs, juz, page starts): Tanzil Project, CC BY 3.0, https://tanzil.net. The files are bundled unmodified, with their copyright notice, and verified by checksum.';

  @override
  String get creditsImages =>
      'Printed Mushaf pages: artwork from the digital Madinah Mushaf (Hafs, 1441 AH) of the King Fahd Glorious Quran Printing Complex, https://qurancomplex.gov.sa; all rights remain with the Complex. Vector pages and ayah positions: the Quran.ws project (quran-svg), CC BY 4.0, https://quran.ws. Pages are downloaded when needed, and every file is verified by checksum before it is shown.';

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
  String get adhkarQuickAccess => 'Quick access';

  @override
  String get adhkarFavoriteAdd => 'Add to favourites';

  @override
  String get adhkarFavoriteRemove => 'Remove from favourites';

  @override
  String adhkarListCount(String count) {
    return '$count lists';
  }

  @override
  String get weeklyReminders => 'Weekly reminders';

  @override
  String weeklyReminderWhen(String day, String time) {
    return 'Every $day · $time';
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
      'Choose approximate or precise location, or select a place on the map. Times are calculated on your phone.';

  @override
  String get prayerLocate => 'Use my location';

  @override
  String get prayerUpdateLocation => 'Update my location';

  @override
  String get prayerChooseMap => 'Choose a place on the map';

  @override
  String get prayerChooseMapHint => 'Set your place manually with Google Maps';

  @override
  String get prayerMapTitle => 'Choose your place';

  @override
  String get prayerMapHint =>
      'Move the map until the tip of the pin points at your place';

  @override
  String get prayerMapOnline => 'The map and search need the internet.';

  @override
  String get prayerMapNoPlace => 'No place chosen yet';

  @override
  String get prayerMapCurrentLocation => 'Use my current location';

  @override
  String get prayerMapSearchHint => 'Search for a city or address';

  @override
  String get prayerMapSearch => 'Search for a place';

  @override
  String get prayerMapNoResults => 'No place matched that name.';

  @override
  String get prayerLocationUnavailable =>
      'Could not find your location. Check location services and permission, or choose a place on the map.';

  @override
  String get prayerMapSave => 'Use this place';

  @override
  String get prayerMapSelect => 'Tap the map to choose a place';

  @override
  String prayerPlaceNamed(String name) {
    return 'Location: $name';
  }

  @override
  String get prayerMapSaving => 'Saving…';

  @override
  String get locationOffMessage =>
      'Location is switched off on your phone. Turn it on, then come back here.';

  @override
  String get locationOffAction => 'Turn on location';

  @override
  String get locationDeniedMessage =>
      'The app needs your OK to know where you are. Press the button again and choose “Allow”.';

  @override
  String get locationBlockedMessage =>
      'Location is blocked for this app. Open settings and allow it.';

  @override
  String get locationBlockedAction => 'Open settings';

  @override
  String prayerPlaceLine(String latitude, String longitude) {
    return 'Coordinates: $latitude, $longitude';
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
      'A notification when the time comes. With the Adhan settings on, the adhan plays by itself; otherwise it uses your phone\'s notification sound.';

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
  String get prayerJumuah => 'Jumu\'ah';

  @override
  String prayerSoonTitle(String prayer) {
    return '$prayer is near';
  }

  @override
  String prayerSoonBody(int count, String number) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$number minutes to the adhan',
      one: '1 minute to the adhan',
    );
    return '$_temp0';
  }

  @override
  String prayerSoonChannelNamed(String prayer) {
    return 'Before the prayer · $prayer';
  }

  @override
  String get prayerSoonSwitch => 'Reminder before the prayer';

  @override
  String get prayerSoonHint =>
      'A notification a while before the adhan, for the prayers whose alert is on.';

  @override
  String get prayerSoonMinutes => 'Before the adhan';

  @override
  String minutesCount(int count, String number) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$number minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get qiblaTitle => 'Qibla';

  @override
  String get shortcutPrayer => 'Prayer times and adhan';

  @override
  String get shortcutAdhkar => 'Adhkar and duas';

  @override
  String get shortcutReader => 'Continue reading';

  @override
  String get qiblaTileSubtitle => 'A compass that points to the Kaaba';

  @override
  String qiblaDirectionLine(String degrees, String direction) {
    return 'Qibla: $degrees° · $direction';
  }

  @override
  String qiblaSemantics(String degrees, String direction) {
    return 'Qibla compass. The Qibla is $degrees degrees from north, towards the $direction.';
  }

  @override
  String get qiblaAligned => 'You are facing the Qibla';

  @override
  String qiblaTurnRight(String degrees) {
    return 'Turn right $degrees°';
  }

  @override
  String qiblaTurnLeft(String degrees) {
    return 'Turn left $degrees°';
  }

  @override
  String get qiblaHintFlat =>
      'Hold the phone flat, away from metal, speakers and magnetic cases.';

  @override
  String get qiblaHintCalibrate =>
      'If the dial jumps, move the phone in a figure 8 to calibrate it.';

  @override
  String get adhanSuggestionTitle => 'Set up prayer alerts and adhan';

  @override
  String get adhanSuggestionBody =>
      'Choose your location and prayer alerts, then choose the adhan voice you prefer.';

  @override
  String get adhanSuggestionAction => 'Set up prayer times';

  @override
  String get qiblaNoSensor =>
      'This device has no compass sensor. The dial shows the Qibla measured from north: find north with a compass or the sun, then turn by that angle.';

  @override
  String get qiblaPlaceNote =>
      'Worked out on your phone from your approximate place. Nothing is sent anywhere.';

  @override
  String get compassNorth => 'north';

  @override
  String get compassNorthEast => 'north-east';

  @override
  String get compassEast => 'east';

  @override
  String get compassSouthEast => 'south-east';

  @override
  String get compassSouth => 'south';

  @override
  String get compassSouthWest => 'south-west';

  @override
  String get compassWest => 'west';

  @override
  String get compassNorthWest => 'north-west';

  @override
  String get compassLetterNorth => 'N';

  @override
  String get compassLetterEast => 'E';

  @override
  String get compassLetterSouth => 'S';

  @override
  String get compassLetterWest => 'W';

  @override
  String get hijriMonth1 => 'Muharram';

  @override
  String get hijriMonth2 => 'Safar';

  @override
  String get hijriMonth3 => 'Rabi\' al-Awwal';

  @override
  String get hijriMonth4 => 'Rabi\' al-Thani';

  @override
  String get hijriMonth5 => 'Jumada al-Awwal';

  @override
  String get hijriMonth6 => 'Jumada al-Thani';

  @override
  String get hijriMonth7 => 'Rajab';

  @override
  String get hijriMonth8 => 'Sha\'ban';

  @override
  String get hijriMonth9 => 'Ramadan';

  @override
  String get hijriMonth10 => 'Shawwal';

  @override
  String get hijriMonth11 => 'Dhu al-Qi\'dah';

  @override
  String get hijriMonth12 => 'Dhu al-Hijjah';

  @override
  String hijriDateLine(String day, String month, String year) {
    return '$day $month $year AH';
  }

  @override
  String get prayerWidgetEmpty => 'Open Mushafi to refresh prayer times';

  @override
  String get adhanTitle => 'Adhan';

  @override
  String get adhanTileSubtitle => 'The voice and how the alert behaves';

  @override
  String get adhanSectionAlert => 'Alert';

  @override
  String get adhanPlaySwitch => 'Play the adhan at prayer time';

  @override
  String get adhanPlayHint =>
      'It starts by itself, with a notice that stays on screen until you stop it, like a call.';

  @override
  String get adhanFlipSwitch => 'Stop when the phone is turned face down';

  @override
  String get adhanFlipHint => 'Put the screen against the table to silence it.';

  @override
  String get adhanAnnounceSwitch => 'Announce the prayer before the adhan';

  @override
  String get adhanAnnounceHint =>
      '\"It is now time for the Dhuhr adhan\", then the adhan.';

  @override
  String get adhanDuaSwitch => 'Dua after the adhan';

  @override
  String get adhanDuaHint =>
      '\"O Allah, Lord of this perfect call…\" once the adhan ends.';

  @override
  String get adhanDuaShaarawy => 'Sheikh Muhammad Metwalli Al-Shaarawy';

  @override
  String get adhanDuaMishary => 'Sheikh Mishary Rashid Alafasy';

  @override
  String get adhanFajrVoices => 'Fajr adhan';

  @override
  String get adhanFajrVoicesHint =>
      'Fajr has its own adhan, with \"Prayer is better than sleep\".';

  @override
  String get adhanTest => 'Try the alert now';

  @override
  String get adhanTestHint => 'Plays the chosen voice and shows the notice.';

  @override
  String get adhanTestTitle => 'Test: time for prayer';

  @override
  String get adhanTestBody =>
      'This is how the alert will look. Tap Stop to end it.';

  @override
  String get adhanVoices => 'Voices';

  @override
  String get adhanVoicesHint =>
      'Listen before you download. A downloaded voice works without internet.';

  @override
  String get adhanListen => 'Listen';

  @override
  String get adhanPreviewFailed =>
      'Could not play the preview. Check your connection, or download the voice to hear it from your phone.';

  @override
  String get adhanStopListening => 'Stop listening';

  @override
  String adhanDownload(String size) {
    return 'Download ($size)';
  }

  @override
  String adhanDownloading(String percent) {
    return 'Downloading $percent';
  }

  @override
  String get adhanCancel => 'Cancel';

  @override
  String get adhanDelete => 'Delete download';

  @override
  String get adhanUse => 'Use this voice';

  @override
  String get adhanInUse => 'In use';

  @override
  String get adhanBuiltIn => 'Built in';

  @override
  String adhanSizeMb(String size) {
    return '$size MB';
  }

  @override
  String get adhanInfo => 'Source and licence';

  @override
  String adhanCreditLine(String credit) {
    return 'Credit: $credit';
  }

  @override
  String adhanLicenseLine(String license) {
    return 'Licence: $license';
  }

  @override
  String adhanSourceLine(String source) {
    return 'Source: $source';
  }

  @override
  String get adhanDownloadNetwork =>
      'Could not download. Check your connection and try again.';

  @override
  String get adhanDownloadIntegrity =>
      'The file was not what was expected, so it was not saved.';

  @override
  String get adhanDownloadBusy =>
      'The server is busy right now. Try again in a few minutes.';

  @override
  String get adhanCustomTitle => 'From your phone';

  @override
  String get adhanCustomHint =>
      'Pick an adhan recording you already have, such as the voice of a muezzin you love. It is copied into the app and stays on this phone. Use only recordings you have the right to use.';

  @override
  String get adhanCustomChoose => 'Choose a file';

  @override
  String get adhanCustomReplace => 'Choose another file';

  @override
  String adhanCustomTooLarge(String size) {
    return 'That file is too large. Pick one under $size MB.';
  }

  @override
  String get adhanUnsupported =>
      'On iPhone, the system lets no app start a long sound by itself. So the prayer-time alert rings with the first 30 seconds of the adhan (the Fajr adhan at Fajr), and it comes through Focus.';

  @override
  String get adhanLicenseNote =>
      'Recordings of well-known muezzins are not included because none is freely licensed. Every voice here is shared under the licence shown.';

  @override
  String get adhanStopAction => 'Stop the adhan';

  @override
  String get adhanChannelName => 'Adhan';

  @override
  String get settingsHaptics => 'Vibration';

  @override
  String get settingsHapticsHint =>
      'A light tick for each count, a firmer one when a dhikr is done.';

  @override
  String get settingsWidgetSeconds => 'Seconds on the prayer widgets';

  @override
  String get settingsWidgetSecondsHint =>
      'The home-screen widgets count the time left to the second. This uses a little battery while they are on screen.';

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
  String get settingsOfflineHint =>
      'Download Mushaf pages to read without internet';

  @override
  String get settingsRemindersHint => 'The adhkar, and Surat Al-Kahf on Friday';

  @override
  String get settingsViewHint =>
      'Colours, language, text size and how the Mushaf is shown';

  @override
  String get settingsFeel => 'Motion and touch';

  @override
  String get settingsPrivacyHint => 'Crash reports and the privacy policy';

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
  String get adhkarResetEntry => 'Restart this dhikr';

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
      'Adhkar and duas: morning and evening adhkar from the Seen Arabic database (MIT licence), https://github.com/Seen-Arabic/Morning-And-Evening-Adhkar-DB. The others are cut from the hadiths\' own text in the hadith-api editions (The Unlicense), https://github.com/fawazahmed0/hadith-api, with their references and Al-Albani\'s grading. The order of Hisn al-Muslim\'s chapters (Sa\'id al-Qahtani) comes from the rn0x/Adhkar-json index; its text is not copied. All bundled and checked by checksum.';

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
  String get indexHizb => 'Hizb';

  @override
  String get indexSajda => 'Sajdas';

  @override
  String get pinchLandscapeHint => 'For bigger text, turn your phone sideways';

  @override
  String get pinchLandscapeAction => 'Rotate';

  @override
  String get pinchTextHint => 'For bigger text, show the page as text';

  @override
  String get pinchTextAction => 'Show text';

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
  String sajdaTitle(String surah) {
    return 'Sajda in $surah';
  }

  @override
  String sajdaAt(String ayah, String juz) {
    return 'Ayah $ayah · Juz $juz';
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
  String get textSizeMushaf => 'Mushaf text size';

  @override
  String get textSizeAdhkar => 'Adhkar, evidence and tafsir text size';

  @override
  String get textSizeHint =>
      'You can also change it with two fingers on the text.';

  @override
  String get readerLoadError => 'The Mushaf could not be loaded.';

  @override
  String get readerProvisional =>
      'Provisional layout: ayahs follow the Madinah pages, line breaks are not yet exact.';

  @override
  String get creditsQuranFont =>
      'Quran font: Amiri Quran by Khaled Hosny and Sebastian Kosch, SIL Open Font License 1.1, https://github.com/aliftype/amiri.';

  @override
  String get creditsMushafScript =>
      'Mushaf text, script and Al-Tafsir Al-Muyassar: King Fahd Glorious Quran Printing Complex, Madinah (Uthmanic Hafs script, version 2.0, and the Tafseer Mouaser data, version 3), https://qurancomplex.gov.sa. Bundled unchanged and checked by checksum. The Complex offers them for digital use with credit; all rights remain with it.';

  @override
  String hizbTitle(String number) {
    return 'Hizb $number';
  }

  @override
  String get copyAyah => 'Copy ayah';

  @override
  String get tafsirAction => 'Tafsir';

  @override
  String get tafsirTitle => 'Al-Tafsir Al-Muyassar';

  @override
  String tafsirOfHafsAyah(String number) {
    return 'Tafsir of ayah $number as Hafs numbers it';
  }

  @override
  String get tafsirCredit =>
      'Al-Tafsir Al-Muyassar, by a group of scholars of tafsir, from the King Fahd Glorious Quran Printing Complex\'s data (version 3), unchanged. It is in Arabic.';

  @override
  String get tafsirCopy => 'Copy the tafsir';

  @override
  String get tafsirCopied => 'Tafsir copied';

  @override
  String get tafsirLoadError => 'The tafsir could not be loaded.';

  @override
  String get ayahCopied => 'Ayah copied';

  @override
  String get shareAyah => 'Share';

  @override
  String get shareAyahsTitle => 'Share ayahs';

  @override
  String get shareAsText => 'Share as text';

  @override
  String get shareAsImage => 'Share as image';

  @override
  String get printAyahs => 'Print verses';

  @override
  String get printFailed => 'Could not print. Please try again.';

  @override
  String get widgetPreviewIosHint =>
      'Previews show the default Android designs. On iPhone, widgets follow your choices and Home Screen appearance.';

  @override
  String get copyText => 'Copy';

  @override
  String get ayahsCopied => 'Copied';

  @override
  String get shareFailed => 'Could not share';

  @override
  String shareGetApp(String app) {
    return 'Get $app:';
  }

  @override
  String shareAppMessage(String app) {
    return 'I recommend $app: the Mushaf, adhkar and prayer times in one place.';
  }

  @override
  String get shareApp => 'Share the app';

  @override
  String get shareAppHint => 'Send the app\'s link to someone you love';

  @override
  String shareLimit(String count) {
    return 'Up to $count ayahs at a time';
  }

  @override
  String get shareFrom => 'From';

  @override
  String get shareTo => 'To';

  @override
  String get shareSurah => 'Surah';

  @override
  String get shareAyahField => 'Ayah';

  @override
  String sharePicture(String index, String count) {
    return 'Picture $index of $count';
  }

  @override
  String get sharePicturesField => 'Pictures';

  @override
  String get sharePicturesFewer => 'One picture fewer';

  @override
  String get sharePicturesMore => 'One picture more';

  @override
  String get sharePicturesAuto => 'Automatic';

  @override
  String surahAyah(String surah, String ayah) {
    return '$surah $ayah';
  }

  @override
  String get selectAyahs => 'Select more ayahs';

  @override
  String get selectionHint =>
      'Tap the last ayah you want, even on another page';

  @override
  String selectionCount(int count, String number) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$number ayahs',
      one: '1 ayah',
    );
    return '$_temp0';
  }

  @override
  String get cancelSelection => 'Cancel selection';

  @override
  String selectionLimitReached(String count) {
    return 'That is the most at once: $count ayahs';
  }

  @override
  String ayahRange(String first, String last) {
    return '$first–$last';
  }

  @override
  String pageRange(String first, String last) {
    return 'Pages $first–$last';
  }

  @override
  String ayahShareReference(String surah, String ayahs, String page) {
    return '[$surah: $ayahs · $page]';
  }

  @override
  String get previousAyah => 'Previous ayah';

  @override
  String get nextAyah => 'Next ayah';

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
  String get surahFrame => 'Surah name frame';

  @override
  String get surahFrameCartouche => 'Pointed';

  @override
  String get surahFrameClassic => 'Classic';

  @override
  String get surahFrameArch => 'Scalloped';

  @override
  String get surahFrameMinimal => 'Simple';

  @override
  String get readerLandscape => 'Landscape reading';

  @override
  String get readerPortrait => 'Portrait reading';

  @override
  String get printedPageError =>
      'The page could not be loaded from the server. Try again in a moment.';

  @override
  String get printedPageDownload => 'Download the whole reading';

  @override
  String get printedPageOffline =>
      'There is no internet right now, and this page is not saved on your phone yet. Pages you opened before work without the internet. Connect and try again, or download the whole reading.';

  @override
  String printedPageLabel(String number) {
    return 'Page $number of the printed Mushaf';
  }

  @override
  String get offlineMushaf => 'Offline Mushaf';

  @override
  String get offlineMushafIntro =>
      'Download the printed Mushaf pages to read without internet. The download carries on after you close the app, and every page is verified before it is shown.';

  @override
  String packNotDownloaded(String size) {
    return 'Not downloaded · about $size MB';
  }

  @override
  String get packStateError => 'Could not read the download state';

  @override
  String get mushafEdition => 'Reading';

  @override
  String get editionLimitedNote =>
      'Copying an ayah, its tafsir, ayah bookmarks and search work on the Hafs reading. Other readings show the Mushaf pages only.';

  @override
  String get editionInUse => 'Reading now';

  @override
  String get offlinePickHint =>
      'Tap a reading to read with it. It works without downloading while you are online.';

  @override
  String get packChecking => 'Checking what is on the device…';

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
  String packNotifyPausedTitle(String name) {
    return '$name download paused';
  }

  @override
  String get packNotifyPausedBody => 'Tap Resume to carry on.';

  @override
  String packInstallingProgress(String percent) {
    return 'Checking and preparing the pages · $percent%';
  }

  @override
  String get nextSurah => 'Next surah';

  @override
  String get goToPage => 'Go to page';

  @override
  String get goToPageAction => 'Go';

  @override
  String get fineScrub => 'Fine scroll';

  @override
  String get scrubCancelHint => 'Drag up to cancel';

  @override
  String get scrubCancelNow => 'Lift to cancel';

  @override
  String get scrubberOpen => 'Browse pages';

  @override
  String get scrubberClose => 'Close the page bar';

  @override
  String scrubberPlace(String surah, String juz) {
    return '$surah · $juz';
  }

  @override
  String pageOfTotal(String page, String total) {
    return 'Page $page of $total';
  }

  @override
  String get bookmarkPage => 'Bookmark this page';

  @override
  String get removePageBookmark => 'Remove this page\'s bookmark';

  @override
  String get surahOrderCaption => 'Order';

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
    return '$pages files ($size MB) will be deleted for good. The printed Mushaf will not work offline until you download it again.';
  }

  @override
  String get packDeleteAck => 'I understand and want to delete it';

  @override
  String get packDeletePermanently => 'Delete permanently';

  @override
  String get printedFallbackNotice =>
      'The printed page could not be loaded, so its text is shown.';

  @override
  String get printedSwitchedToText =>
      'There is no internet, and this page is not on your phone, so the Mushaf is now shown as text. The printed Mushaf comes back by itself when the internet does.';

  @override
  String get printedBackOnline =>
      'The internet is back, and so is the printed Mushaf.';

  @override
  String get readerTextUntilOnline =>
      'Text is shown because the printed pages need the internet. The printed Mushaf comes back when the internet does. To read it printed without the internet, download it under Offline Mushaf.';

  @override
  String get adhanExactNote =>
      'Without exact alarms the adhan does not play: only a plain notification comes, and it may be a few minutes late.';

  @override
  String get adhanBatteryNote =>
      'Battery saving can stop the adhan or hold it back. Open the app\'s settings, then Battery, and choose Unrestricted (on some phones: No restrictions, or turn on Auto-start).';

  @override
  String get adhanBatteryAction => 'Open the app\'s settings';

  @override
  String get prayerSoonCountdownSwitch => 'Count down to the adhan';

  @override
  String get prayerSoonCountdownHint =>
      'The reminder stays, with a large countdown of the time left to the second until the adhan, then goes by itself. Its Remove button takes it away at once.';

  @override
  String prayerSoonCountdownBody(String time) {
    return 'Left until the adhan · $time';
  }

  @override
  String get prayerSoonDismiss => 'Remove';

  @override
  String get fastingChannelName => 'Sunnah fasts';

  @override
  String get fastingReminderTitle => 'A sunnah fast tomorrow';

  @override
  String get fastingMonday => 'Tomorrow is Monday, and fasting it is sunnah.';

  @override
  String get fastingThursday =>
      'Tomorrow is Thursday, and fasting it is sunnah.';

  @override
  String fastingWhiteDay(String day) {
    return 'Tomorrow, day $day of the Hijri month, is one of the white days, and fasting them is sunnah.';
  }

  @override
  String get fastingArafah =>
      'Tomorrow is the Day of Arafah, and fasting it is sunnah for those not on Hajj.';

  @override
  String get fastingTasua =>
      'Tomorrow is Tasu\'a, the ninth of Muharram, and fasting it with Ashura is sunnah.';

  @override
  String get fastingAshura =>
      'Tomorrow is Ashura, the tenth of Muharram, and fasting it is sunnah.';

  @override
  String get fastingShawwal =>
      'Fasting six days of Shawwal after the Eid is sunnah, and you can begin tomorrow.';

  @override
  String get fastingSection => 'Sunnah fasts';

  @override
  String get fastingSectionHint =>
      'A reminder the evening before. Hijri dates follow the Umm al-Qura calendar and may be a day off the moon sighting where you are, so no reminder falls on a day that could be the Eid there.';

  @override
  String get fastingMondayThursday => 'Mondays and Thursdays';

  @override
  String get fastingWhiteDays => 'The white days';

  @override
  String fastingWhiteDaysHint(String first, String second, String third) {
    return 'The ${first}th, ${second}th and ${third}th of each Hijri month';
  }

  @override
  String get fastingArafahSwitch => 'The Day of Arafah';

  @override
  String get fastingAshuraSwitch => 'Tasu\'a and Ashura';

  @override
  String get fastingShawwalSwitch => 'Six days of Shawwal';

  @override
  String fastingNext(String date) {
    return 'Next: $date';
  }

  @override
  String get notificationSettings => 'Settings';

  @override
  String printedTextInstead(String reading) {
    return 'The Mushaf shows as typeset text, in Hafs. The printed $reading Mushaf comes back when the internet does.';
  }

  @override
  String get printedBackSaved =>
      'Every page of the printed Mushaf is on your phone now, so it is back, internet or not.';

  @override
  String get printedReadText => 'Read the typeset text (Hafs)';

  @override
  String get printedSlowNotice =>
      'The printed page is slow to come, so its text is shown until it does.';

  @override
  String printedSavedIn(String reading) {
    return 'This page is saved in $reading: show it';
  }

  @override
  String printedNearestSaved(String page) {
    return 'Go to the nearest saved page ($page)';
  }

  @override
  String printedShownIn(String reading) {
    return 'Now showing $reading, whose copy of this page is on your phone.';
  }

  @override
  String printedPageSavedIn(String reading) {
    return 'This page is saved in $reading.';
  }

  @override
  String get printedShowSaved => 'Show it';

  @override
  String get prayerTuningTitle => 'Adjust the times';

  @override
  String get prayerTuningTileSubtitle =>
      'Move each prayer, summer time, height and the Hijri date';

  @override
  String get prayerTuningOffsetsTitle => 'Move the prayers';

  @override
  String get prayerTuningOffsetsHint =>
      'Minutes added to or taken from each prayer\'s time. The alerts, the adhan and the widgets follow them. Zero is the calculated time.';

  @override
  String get prayerTuningAsCalculated => 'As calculated';

  @override
  String prayerTuningEarlier(String minutes) {
    return '$minutes earlier';
  }

  @override
  String prayerTuningLater(String minutes) {
    return '$minutes later';
  }

  @override
  String get prayerTuningEarlierButton => 'One minute earlier';

  @override
  String get prayerTuningLaterButton => 'One minute later';

  @override
  String get prayerTuningResetAll =>
      'Put every prayer back to the calculated time';

  @override
  String get prayerTuningDaylightTitle => 'Summer time';

  @override
  String get prayerTuningDaylightHint =>
      'The times follow your phone\'s clock. If it is not on your place\'s time (on summer time when it is winter, or the other way round), choose the right one here.';

  @override
  String get prayerTuningDaylightAuto => 'Follow the phone';

  @override
  String get prayerTuningDaylightSummer => 'Summer';

  @override
  String get prayerTuningDaylightWinter => 'Winter';

  @override
  String get prayerTuningPhoneSummer =>
      'Your phone\'s clock is on summer time now.';

  @override
  String get prayerTuningPhoneWinter =>
      'Your phone\'s clock is on winter (standard) time now.';

  @override
  String get prayerTuningDaylightShifted =>
      'The times are shifted a whole hour from your phone\'s clock.';

  @override
  String get prayerTuningElevationTitle => 'Height above sea level';

  @override
  String get prayerTuningElevationHint =>
      'It moves sunrise and Maghrib only: the higher you are, the earlier the sun rises and the later it sets. If you live on a high floor, type your own height.';

  @override
  String get prayerTuningElevationField => 'Height in metres';

  @override
  String prayerTuningElevationDevice(String metres) {
    return 'From the phone\'s GPS: $metres';
  }

  @override
  String get prayerTuningElevationNone =>
      'The phone gave no height, so the times are worked out at sea level.';

  @override
  String prayerTuningElevationManual(String metres) {
    return 'A height you typed: $metres';
  }

  @override
  String get prayerTuningElevationUseDevice => 'Use the phone\'s reading';

  @override
  String get prayerTuningElevationSave => 'Save';

  @override
  String prayerTuningElevationInvalid(String min, String max) {
    return 'Type a number from $min to $max';
  }

  @override
  String prayerTuningElevationEffect(String minutes) {
    return 'Sunrise is about $minutes earlier and Maghrib about $minutes later.';
  }

  @override
  String metersCount(String number) {
    return '$number m';
  }

  @override
  String get prayerTuningHijriTitle => 'Adjust the Hijri date';

  @override
  String get prayerTuningHijriHint =>
      'The calculated calendar can be a day or two off the moon sighting in your country. This changes the date shown and the fasting reminders.';

  @override
  String prayerTuningHijriToday(String date) {
    return 'Today: $date';
  }

  @override
  String get prayerTuningHijriNone => 'As in the calendar';

  @override
  String prayerTuningHijriForward(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days forward',
      one: '1 day forward',
    );
    return '$_temp0';
  }

  @override
  String prayerTuningHijriBack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days back',
      one: '1 day back',
    );
    return '$_temp0';
  }

  @override
  String get prayerTuningHijriBackButton => 'One day back';

  @override
  String get prayerTuningHijriForwardButton => 'One day forward';

  @override
  String get prayerTuningNeedsPlace =>
      'Choose your place first on the prayer times page: the adjustments are made to the times of your place.';

  @override
  String get customReminderBody => 'A reminder you made.';

  @override
  String get customReminderChannel => 'My reminders';

  @override
  String get myRemindersTitle => 'My reminders';

  @override
  String get myRemindersHint =>
      'Reminders you write yourself: daily, weekly or monthly, at one time or more.';

  @override
  String get myRemindersEmpty =>
      'You have not added a reminder yet. Add the first: a medicine, a daily reading, an appointment, a visit to family.';

  @override
  String get reminderAdd => 'Add a reminder';

  @override
  String reminderLimit(String count) {
    return 'You have reached the limit ($count reminders). Delete one to add another.';
  }

  @override
  String get remindersAdhkarSection => 'Daily adhkar';

  @override
  String get reminderEveryDay => 'Every day';

  @override
  String reminderWeeklyOn(String days) {
    return 'Every $days';
  }

  @override
  String reminderMonthlyOn(String day) {
    return 'On day $day of every month';
  }

  @override
  String reminderSummary(String when, String times) {
    return '$when · $times';
  }

  @override
  String get reminderNewTitle => 'New reminder';

  @override
  String get reminderEditTitle => 'Edit the reminder';

  @override
  String get reminderTitleField => 'Reminder title';

  @override
  String get reminderTitleHint =>
      'For example: medicine, daily reading, visiting family';

  @override
  String get reminderNoteField => 'What shows under the title (optional)';

  @override
  String get reminderRepeatLabel => 'How often?';

  @override
  String get reminderRepeatDaily => 'Daily';

  @override
  String get reminderRepeatWeekly => 'Weekly';

  @override
  String get reminderRepeatMonthly => 'Monthly';

  @override
  String get reminderDaysLabel => 'On which days?';

  @override
  String get reminderMonthDayLabel => 'On which day of the month?';

  @override
  String reminderMonthDayHint(String max) {
    return 'Only days up to $max, so that every month has them.';
  }

  @override
  String get reminderTimesLabel => 'At what time?';

  @override
  String get reminderTimesHint => 'You can add more than one time in a day.';

  @override
  String get reminderAddTime => 'Add a time';

  @override
  String get reminderRemoveTime => 'Remove this time';

  @override
  String reminderTimesLimit(String count) {
    return 'At most $count times a day.';
  }

  @override
  String reminderFirstAt(String when) {
    return 'First reminder: $when';
  }

  @override
  String get reminderSave => 'Save the reminder';

  @override
  String get reminderDelete => 'Delete the reminder';

  @override
  String reminderDeleteConfirm(String title) {
    return 'Delete the reminder “$title”?';
  }

  @override
  String get reminderDeleteYes => 'Yes, delete it';

  @override
  String get reminderProblemTitle => 'Write a title for the reminder.';

  @override
  String get reminderProblemTime => 'Add at least one time.';

  @override
  String get reminderProblemDay => 'Choose at least one day.';

  @override
  String reminderProblemMoments(String count) {
    return 'Too many times on too many days. Use fewer (at most $count a week or month).';
  }

  @override
  String get reminderOff => 'Off';

  @override
  String get reminderKeep => 'No, keep it';

  @override
  String iqamaTitle(String prayer) {
    return 'The iqama of $prayer';
  }

  @override
  String get iqamaBody =>
      'The prayer is established, the prayer is established';

  @override
  String get iqamaChannelName => 'The iqama';

  @override
  String get iqamaPageTitle => 'The iqama';

  @override
  String get iqamaTileSubtitle =>
      'A notice at each prayer\'s iqama, set to a time after the adhan';

  @override
  String get iqamaIntro =>
      'At the iqama you get a notice with «قد قامت الصلاة، قد قامت الصلاة» (the prayer is established), not the whole iqama. Set here how many minutes after the adhan each prayer is established at your mosque.';

  @override
  String get iqamaSwitch => 'Iqama notice';

  @override
  String get iqamaSwitchHint => 'It comes at the iqama of the five prayers.';

  @override
  String get iqamaSoundSwitch => 'Notice sound';

  @override
  String get iqamaSoundHint => 'Turn it off for a silent notice.';

  @override
  String get iqamaTimesTitle => 'How long after the adhan?';

  @override
  String get iqamaTimesHint =>
      'It is usually longer after Fajr and shorter after Maghrib. Set each prayer to when it is established at your mosque.';

  @override
  String iqamaAfterLine(String minutes) {
    return '$minutes after the adhan';
  }

  @override
  String iqamaAt(String time) {
    return 'Iqama $time';
  }

  @override
  String get iqamaEarlierButton => 'One minute less';

  @override
  String get iqamaLaterButton => 'One minute more';

  @override
  String get iqamaResetAll => 'Put every prayer back to the usual';

  @override
  String get prayerSoonSoundSwitch => 'Reminder sound';

  @override
  String get prayerSoonSoundHint => 'Turn it off for a silent reminder.';

  @override
  String prayerTuningSummaryPlace(String place, String method) {
    return 'These are the times of $place, worked out by $method.';
  }

  @override
  String get prayerTuningSummaryNone =>
      'You have changed nothing: the times are as calculated. Change here what differs from the truth at your mosque or in your country.';

  @override
  String get prayerTuningSummaryChanged =>
      'What you changed from the calculation:';

  @override
  String prayerTuningChipOffset(String prayer, String change) {
    return '$prayer: $change';
  }

  @override
  String prayerTuningChipDaylight(String value) {
    return 'Time: $value';
  }

  @override
  String prayerTuningChipElevation(String metres) {
    return 'Height: $metres';
  }

  @override
  String prayerTuningChipHijri(String shift) {
    return 'Hijri: $shift';
  }

  @override
  String prayerTuningCalculated(String time) {
    return 'Calculated $time';
  }

  @override
  String prayerTuningElevationUsed(String metres) {
    return 'Height used in the calculation: $metres';
  }

  @override
  String get creditsAudioIqama =>
      'The sound of the iqama notice, the phrase «قد قامت الصلاة» twice: from the iqama of the Isha prayer by Sheikh Majed Abbas at the Grand Mosque in Makkah, from a recording on archive.org (https://archive.org/details/IqamaMakkahIsha3111434SheikhMajedAbbas). The clip was trimmed and its volume set; the recitation is unchanged. Permission is being asked for.';

  @override
  String get creditsAudioNear =>
      'The sound of the reminder «اقتربت صلاة …» (the prayer is near): clips from a copy on archive.org (https://archive.org/details/20260909_20260909_2244, «تنبيه قبل الصلاة») whose author is not known. They were trimmed and their volume set. Permission is being asked for.';

  @override
  String get iqamaCardLabel => 'The iqama';

  @override
  String iqamaIn(String time) {
    return 'in $time';
  }

  @override
  String iqamaCardWhen(String time) {
    return 'Iqama at $time';
  }

  @override
  String iqamaCardSubtitle(String prayer, String left) {
    return '$prayer · iqama in $left';
  }
}
