# Google Maps keys

The manual prayer-location picker uses Google Maps on Android and iOS. Keys
stay local and must never be committed.

## Google Cloud

1. Enable billing for the Google Cloud project.
2. Enable Maps SDK for Android and Maps SDK for iOS.
3. Make separate restricted keys for each platform.

Restrict the Android key to package `net.mrecode.mre_quran` and the SHA-1 of
each signing certificate used to build the app. Restrict the iOS key to bundle
identifier `net.mrecode.mreQuran`.

## Android

Add the key to the already-local `android/local.properties` file:

```properties
MAPS_API_KEY=your-android-restricted-key
```

## iOS

Copy `ios/Flutter/GoogleMaps.xcconfig.example` to
`ios/Flutter/GoogleMaps.xcconfig`, then set the iOS key:

```xcconfig
GOOGLE_MAPS_API_KEY=your-ios-restricted-key
```

Both local files are ignored by Git. A missing key never appears in source
control, but the map cannot render until the matching platform key is added.
