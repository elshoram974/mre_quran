import 'package:flutter/material.dart';
import 'settings_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.controller});
  final SettingsController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('المظهر', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        DropdownButtonFormField<ThemeMode>(
          key: ValueKey(controller.themeMode),
          initialValue: controller.themeMode,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'مظهر التطبيق'),
          items: const [
            DropdownMenuItem(
              value: ThemeMode.system,
              child: Text('حسب الجهاز'),
            ),
            DropdownMenuItem(value: ThemeMode.light, child: Text('فاتح')),
            DropdownMenuItem(value: ThemeMode.dark, child: Text('داكن')),
          ],
          onChanged: controller.saving
              ? null
              : (mode) {
                  if (mode != null) controller.setThemeMode(mode);
                },
        ),
        if (controller.saving) const LinearProgressIndicator(),
        if (controller.error != null) ...[
          const SizedBox(height: 16),
          Semantics(liveRegion: true, child: Text(controller.error!)),
          TextButton(
            onPressed: controller.saving ? null : controller.load,
            child: const Text('إعادة تحميل الإعدادات'),
          ),
        ],
      ],
    ),
  );
}
