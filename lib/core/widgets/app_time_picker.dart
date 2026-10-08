import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_platform.dart';
import '../theme/app_tokens.dart';
import 'app_sheet.dart';

/// Shared time-of-day picker. A wheel in a sheet on iOS, the Material time
/// picker elsewhere.
abstract final class AppTimePicker {
  /// Asks for a time starting at [initialMinutes] (minutes after midnight).
  /// Returns the chosen minutes, or null when dismissed.
  static Future<int?> show({
    required BuildContext context,
    required int initialMinutes,
  }) async {
    if (!context.isCupertino) {
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
          hour: initialMinutes ~/ 60,
          minute: initialMinutes % 60,
        ),
      );
      return picked == null ? null : picked.hour * 60 + picked.minute;
    }
    return AppSheet.show<int>(
      context: context,
      builder: (context) => _WheelBody(initialMinutes: initialMinutes),
    );
  }
}

class _WheelBody extends StatefulWidget {
  const _WheelBody({required this.initialMinutes});

  final int initialMinutes;

  @override
  State<_WheelBody> createState() => _WheelBodyState();
}

class _WheelBodyState extends State<_WheelBody> {
  late int _minutes = widget.initialMinutes;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        height: 180,
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.time,
          use24hFormat: MediaQuery.alwaysUse24HourFormatOf(context),
          initialDateTime: DateTime(
            2000,
            1,
            1,
            widget.initialMinutes ~/ 60,
            widget.initialMinutes % 60,
          ),
          onDateTimeChanged: (value) =>
              _minutes = value.hour * 60 + value.minute,
        ),
      ),
      Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppTokens.gutterCompact,
          0,
          AppTokens.gutterCompact,
          AppTokens.gutterCompact,
        ),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(_minutes),
            child: Text(context.l10n.done),
          ),
        ),
      ),
    ],
  );
}
