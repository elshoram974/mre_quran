import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/data/pack_downloader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('its two streams can each be listened to, and again later: the '
      "plugin's own stream allows a single listener", () async {
    final downloader = BackgroundPackDownloader();
    // What reading the pack's state does, twice over: a retry reads it again.
    for (var round = 0; round < 2; round++) {
      final results = downloader.results.listen((_) {});
      final transfers = downloader.transfers.listen((_) {});
      await results.cancel();
      await transfers.cancel();
    }
  });
}
