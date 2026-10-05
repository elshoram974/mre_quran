import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';

/// Debug only: follows the simulated device's operating system.
///
/// Device Preview keeps the target platform as a separate override. Choosing an
/// iPhone should also switch the app to its iOS chrome, and choosing a Pixel to
/// Android, so this applies the preset's platform whenever the device changes.
void syncPreviewPlatform() {
  final controller = DevicePreview.maybeController;
  if (!kDebugMode || controller == null) return;
  controller.simulationListenable.addListener(() {
    final simulation = controller.simulationListenable.value;
    final presetId = simulation?.presetId;
    if (simulation == null || presetId == null) return;
    for (final preset in controller.presets) {
      if (preset.id != presetId) continue;
      if (simulation.targetPlatform != preset.platform) {
        controller.update((s) => s.copyWith(targetPlatform: preset.platform));
      }
      return;
    }
  });
}
