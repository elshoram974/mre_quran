import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/adhkar/application/adhkar_widget_sync.dart';

void main() {
  test('suggested-dhikr widget payload is plain platform data', () {
    const data = AdhkarWidgetData(
      label: 'ذكر مقترح',
      title: 'أذكار الصباح',
      done: 12,
      total: 33,
      payload: 'adhkar:morning',
      rtl: true,
    );

    expect(data.toMap(), {
      'label': 'ذكر مقترح',
      'title': 'أذكار الصباح',
      'done': 12,
      'total': 33,
      'payload': 'adhkar:morning',
      'rtl': true,
    });
  });
}
