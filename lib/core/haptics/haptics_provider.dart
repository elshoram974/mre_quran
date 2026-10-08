import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'haptics.dart';

/// Whether this device can vibrate. Asked once.
final hapticsSupportedProvider = FutureProvider<bool>(
  (ref) => Haptics.isSupported(),
);
