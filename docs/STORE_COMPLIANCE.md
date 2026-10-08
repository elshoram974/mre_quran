# Store compliance: permissions and data

What the app asks for, when, and why. Check this list before each release.

## Permissions

| Permission | Platform | When it is asked | Why | Notes for review |
|---|---|---|---|---|
| Notifications (`POST_NOTIFICATIONS`, iOS alert and sound) | Android 13+, iOS | When the person turns on a reminder, or starts a download | Adhkar reminders and download progress | Never at launch |
| Approximate location (`ACCESS_COARSE_LOCATION`, iOS "when in use") | Android, iOS | When the person turns on "remind me after each prayer" | To work out prayer times on the device | Approximate only: `ACCESS_FINE_LOCATION` and background location are removed from the manifest. No background use, no foreground service. The location is rounded to about 1 km, kept on the device, and never sent anywhere |
| `RECEIVE_BOOT_COMPLETED` | Android | Not asked (normal permission) | Lets scheduled reminders survive a reboot | |
| Exact alarms (`SCHEDULE_EXACT_ALARM`) | Android 12+ | The person taps "Allow exact timing" on the prayer times page; the system opens its own settings page | Alerts at the minute a prayer begins | **Google Play asks for a declaration** for this permission. Use: "notifies the person at the prayer times they chose". Without it the alerts still come, a few minutes late at worst. To avoid the declaration, delete the one `SCHEDULE_EXACT_ALARM` line in `AndroidManifest.xml`; the "Allow exact timing" button then has nothing to open. `USE_EXACT_ALARM` is not used (it is for alarm and calendar apps) |
| Vibration (`VIBRATE`) | Android | Not asked (normal permission) | Counting adhkar, finishing a step | The person can switch it off in Settings |
| Internet | Android | Normal permission | Downloading offline Mushaf packs | |

The location plugin declares a foreground service the app never starts; `AndroidManifest.xml` removes it, so
the store sees no location foreground service.

## Google Play Data safety

- **Location:** approximate location is *processed on the device only* and not collected or shared. Answer
  "Collected: No".
- **Crash reports:** opt-in, off by default (`docs/DECISIONS.md`). Answer according to the Firebase
  Crashlytics setting when it is configured.
- **No analytics, no ads, no accounts.**
- **Downloads** (`background_downloader`): its `UIDTJobService` (user-initiated data transfer) and the
  `FOREGROUND_SERVICE` permission come from the Mushaf pack downloads. Play may ask for a foreground-service
  declaration: "downloading the Mushaf packs the person asks for". This predates the adhkar work.

## Apple App Privacy

- **Location:** "Coarse Location", used for App Functionality, not linked to the person, not used for tracking,
  and not collected off the device. The `NSLocationWhenInUseUsageDescription` text (Arabic and English) is in
  `ios/Runner/Info.plist`.
- **Notifications:** local only. No push, no `UIBackgroundModes`.
- **Privacy manifest:** the plugins used ship their own `PrivacyInfo.xcprivacy`. Before the first App Store
  upload, add an app-level manifest in Xcode if the build report asks for one (this needs the Xcode project, so
  it is not done from the command line).

## Before a release

1. `aapt dump permissions` on the release APK must list only the rows above (plus plugin normal permissions).
2. Test the permission flows on a device: location refused, notifications refused, both allowed, then turned off.
3. Re-check this file after adding or updating any plugin that declares permissions.
