import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/startup/domain/launch_stall.dart';

void main() {
  const least = Duration(seconds: 8);

  bool worthReporting(String trace, {bool debugBuild = false}) =>
      isLaunchStallWorthReporting(trace, debugBuild: debugBuild, least: least);

  group('a launch that never showed its first frame', () {
    test('is never reported from a debug build', () {
      // Ended on the launch screen, which a release build would report.
      const trace = 'ios 27.2 from icon: engine@120 active@300';
      expect(worthReporting(trace), isTrue);
      expect(worthReporting(trace, debugBuild: true), isFalse);
    });

    test('is never reported when it was a debug build itself', () {
      // The report from a debug run on iOS: the debugger ended a launch that
      // was still starting its Dart.
      expect(
        worthReporting('ios 27.2 debug from icon: engine@2190 active@3813'),
        isFalse,
      );
      expect(
        worthReporting('android 36 debug from icon: start@90 resume@120'),
        isFalse,
      );
    });

    test('is reported when it ended while on the launch screen', () {
      expect(
        worthReporting(
          'android 36 from icon: start@90 resume@120 engine@140 '
          'dart:main@400 dart:services@900 dart:runApp@950',
        ),
        isTrue,
      );
      expect(worthReporting('android 31 from icon:'), isTrue);
    });

    test('is not reported when the person left while it was opening', () {
      // Left before the hold's own limit could have let the frame go.
      expect(
        worthReporting(
          'android 36 from icon: start@90 resume@120 engine@140 pause@3500 '
          'stop@3900',
        ),
        isFalse,
      );
      expect(
        worthReporting('ios 27.2 from icon: engine@150 active@400 pause@7999'),
        isFalse,
      );
    });

    test('is reported when the person waited long before leaving', () {
      expect(
        worthReporting(
          'android 36 from icon: start@90 resume@120 engine@140 '
          'dart:main@400 release:limit@4400 pause@12000 stop@12400',
        ),
        isTrue,
      );
      expect(
        worthReporting('ios 27.2 from icon: engine@150 active@400 pause@8000'),
        isTrue,
      );
    });

    test('counts only the time it was on the screen', () {
      // Left at 2 s, back at 60 s, left again a second later: 3 s in all.
      expect(
        worthReporting(
          'android 36 from icon: start@90 resume@120 pause@2000 stop@2300 '
          'start@60000 resume@60050 pause@61000 stop@61200',
        ),
        isFalse,
      );
      // Pulled the notifications down for a moment, then waited on.
      expect(
        worthReporting(
          'ios 27.2 from icon: engine@150 active@400 pause@1000 active@1500 '
          'pause@9000 background@9100',
        ),
        isTrue,
      );
      // Went to the background before it was ever active.
      expect(
        worthReporting('ios 27.2 from icon: engine@150 background@900'),
        isFalse,
      );
    });

    test('is reported when it ended on the screen after coming back', () {
      expect(
        worthReporting(
          'android 36 from icon: start@90 resume@120 pause@2000 stop@2300 '
          'start@60000 resume@60050',
        ),
        isTrue,
      );
    });

    test('is not reported when its first frame came after all', () {
      expect(
        worthReporting(
          'android 36 from icon: start@90 resume@120 displayed@900 pause@20000',
        ),
        isFalse,
      );
      expect(
        worthReporting('ios 27.2 from icon: active@300 dart:firstFrame@700'),
        isFalse,
      );
    });

    test('reads where it came from without taking it for a step', () {
      // An intent's extra names and a restored activity.
      expect(
        worthReporting(
          'android 36 from ADHAN_TAP[payload] restored: start@90 '
          'resume@120 pause@1000',
        ),
        isFalse,
      );
      expect(
        worthReporting(
          'ios 27.2 from UIApplicationLaunchOptionsShortcutItemKey: '
          'engine@150 active@400',
        ),
        isTrue,
      );
    });
  });
}
