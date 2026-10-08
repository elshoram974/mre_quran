import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'app_sheet.dart';

/// Shared yes/no confirmation, shown as an [AppSheet].
abstract final class AppConfirmSheet {
  /// Asks [title] with [message]. Returns true when the person picks
  /// [confirmLabel], false for [cancelLabel], and false when dismissed.
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
  }) async {
    final result = await AppSheet.show<bool>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppTokens.gutterCompact,
          4,
          AppTokens.gutterCompact,
          20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }
}
