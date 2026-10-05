import 'package:flutter/material.dart';

/// Platform-aware helpers. Always read the platform from the [Theme], never
/// from `defaultTargetPlatform`, so Device Preview and tests can switch it.
extension AppPlatformContext on BuildContext {
  /// Whether UI should follow iOS conventions (liquid glass chrome).
  bool get isCupertino => switch (Theme.of(this).platform) {
    TargetPlatform.iOS || TargetPlatform.macOS => true,
    _ => false,
  };
}
