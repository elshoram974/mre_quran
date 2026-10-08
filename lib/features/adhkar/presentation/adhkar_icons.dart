import 'package:flutter/material.dart';

import '../domain/adhkar_collection.dart';

/// The glyph for a manifest icon name.
IconData adhkarIconData(AdhkarIcon icon) => switch (icon) {
  AdhkarIcon.sunrise => Icons.wb_sunny_outlined,
  AdhkarIcon.sunset => Icons.nights_stay_outlined,
  AdhkarIcon.sleep => Icons.bedtime_outlined,
  AdhkarIcon.wake => Icons.alarm_outlined,
  AdhkarIcon.prayer => Icons.mosque_outlined,
  AdhkarIcon.generic => Icons.auto_awesome_outlined,
};
