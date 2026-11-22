# Store compliance: permissions and data

What the app asks for, when, and why. Check this list before each release.

## Permissions

| Permission | Platform | When it is asked | Why | Notes for review |
|---|---|---|---|---|
| Notifications (`POST_NOTIFICATIONS`, iOS alert and sound) | Android 13+, iOS | When the person turns on a reminder, or starts a download | Adhkar reminders and download progress | Never at launch |
| Foreground location (`ACCESS_COARSE_LOCATION`, `ACCESS_FINE_LOCATION`, iOS "when in use") | Android, iOS | When the person chooses device location or enables a reminder without a saved place | To work out prayer times on the device | The person can choose approximate or precise access where supported, or pick a place manually. Stored coordinates are rounded to four decimals; background location is removed. Google Maps receives the viewed map area when the map is used. |
| `RECEIVE_BOOT_COMPLETED` | Android | Not asked (normal permission) | Lets scheduled reminders survive a reboot | |
| Exact alarms (`SCHEDULE_EXACT_ALARM`) | Android 12+ | The person taps "Allow exact timing" on the prayer times page; the system opens its own settings page | Alerts at the minute a prayer begins | **Google Play asks for a declaration** for this permission. Use: "notifies the person at the prayer times they chose". Without it the alerts still come as plain notifications, a few minutes late at worst, and the adhan does not play. With it each adhan is an alarm clock (`setAlarmClock`, D-054). To avoid the declaration, delete the one `SCHEDULE_EXACT_ALARM` line in `AndroidManifest.xml`; the "Allow exact timing" button then has nothing to open. `USE_EXACT_ALARM` is not used (it is for alarm and calendar apps) |
| Vibration (`VIBRATE`) | Android | Not asked (normal permission) | Counting adhkar, finishing a step | The person can switch it off in Settings |
| Motion sensors (accelerometer, magnetometer) | Android, iOS | Only while the Qibla page is open; no permission is asked or declared | Shows which way the phone points | Read on the device, never stored or sent. `sensors_plus` declares no permission on Android |
| Internet | Android | Normal permission | Downloading offline Mushaf packs | |

The location plugin declares a foreground service the app never starts; `AndroidManifest.xml` removes it, so
the store sees no location foreground service.

## Google Play Data safety

- **Location:** review both approximate and precise location disclosures and Google Maps SDK data handling before release. Prayer calculations run locally and rounded coordinates are saved in app preferences, which may be included in operating-system backups. Loading a map sends the viewed map area to Google Maps. Do not reuse the previous coarse-only declaration without review.
- **Crash reports (Firebase Crashlytics, on by default, can be turned off in the settings):** declare
  "App info and performance → Crash logs" and "Diagnostics", and "Device or other IDs" (the Crashlytics
  installation ID). Collected: Yes. Shared: No (Google processes it as a service provider). Processed
  ephemerally: No. Required: No (the person can turn it off). Purpose: App functionality / Analytics of
  crashes only. Encrypted in transit: Yes. Deletion: reports expire after 90 days.
- **No analytics, no ads, no accounts.**
- **Downloads** (`background_downloader`): its `UIDTJobService` (user-initiated data transfer) and the
  `FOREGROUND_SERVICE` permission come from the Mushaf pack downloads. Play may ask for a foreground-service
  declaration: "downloading the Mushaf packs the person asks for". This predates the adhkar work.

## Apple App Privacy

- **Location:** review both coarse and precise location and Google Maps SDK data handling in App Privacy before release. The `NSLocationWhenInUseUsageDescription` text is in `ios/Runner/Info.plist`.
- **Crash data (Crashlytics):** "Crash Data" and "Other Diagnostic Data", used for App Functionality, not
  linked to the person, not used for tracking.
- **Notifications:** local only. No push, no `UIBackgroundModes`.
- **Privacy manifest:** the plugins used ship their own `PrivacyInfo.xcprivacy`. Before the first App Store
  upload, add an app-level manifest in Xcode if the build report asks for one (this needs the Xcode project, so
  it is not done from the command line).

## Before a release

1. `aapt dump permissions` on the release APK must list only the rows above (plus plugin normal permissions).
2. Test the permission flows on a device: location refused, notifications refused, both allowed, then turned off.
3. Re-check this file after adding or updating any plugin that declares permissions.
