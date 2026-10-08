import 'package:flutter/material.dart';

import '../domain/adhkar_collection.dart';

/// The glyph for a manifest icon name.
IconData adhkarIconData(AdhkarIcon icon) => switch (icon) {
  AdhkarIcon.sunrise => Icons.wb_sunny_outlined,
  AdhkarIcon.sunset => Icons.nights_stay_outlined,
  AdhkarIcon.sleep => Icons.bedtime_outlined,
  AdhkarIcon.wake => Icons.alarm_outlined,
  AdhkarIcon.prayer => Icons.mosque_outlined,
  AdhkarIcon.home => Icons.home_outlined,
  AdhkarIcon.worry => Icons.healing_outlined,
  AdhkarIcon.janaza => Icons.spa_outlined,
  AdhkarIcon.weather => Icons.cloud_outlined,
  AdhkarIcon.social => Icons.diversity_3_outlined,
  AdhkarIcon.travel => Icons.flight_takeoff_outlined,
  AdhkarIcon.virtue => Icons.auto_awesome_outlined,
  AdhkarIcon.generic => Icons.menu_book_outlined,
};
