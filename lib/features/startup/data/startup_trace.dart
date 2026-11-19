import 'dart:ffi';
import 'dart:io';

import 'package:jni/jni.dart';
import 'package:jni_flutter/jni_flutter.dart';
import 'package:objective_c/objective_c.dart' as objc;

/// The native record of each launch's steps (StartupTrace in Kotlin and
/// Swift): Dart adds its own steps, and takes the trace of an earlier launch
/// that never showed its first frame.
///
/// Dart calls the native code directly and synchronously (JNI on Android,
/// the Objective-C runtime on iOS), with no platform channel in between.
abstract interface class StartupTrace {
  /// The trace of this platform; one that notes nothing elsewhere.
  factory StartupTrace.platform() => Platform.isAndroid
      ? _JniStartupTrace()
      : Platform.isIOS
      ? _ObjCStartupTrace()
      : const _NoStartupTrace();

  /// Notes [step] of the launch under way.
  void mark(String step);

  /// The trace of an earlier launch that stayed on the launch screen, once;
  /// null when none did.
  String? takeStalled();
}

/// Android: the Kotlin object `StartupTrace`, through JNI.
final class _JniStartupTrace implements StartupTrace {
  late final JClass _class = JClass.forName(
    'net/mrecode/mre_quran/StartupTrace',
  );
  late final JStaticMethodId _mark = _class.staticMethodId(
    'mark',
    '(Landroid/content/Context;Ljava/lang/String;)V',
  );
  late final JStaticMethodId _takeStalled = _class.staticMethodId(
    'takeStalled',
    '(Landroid/content/Context;)Ljava/lang/String;',
  );

  @override
  void mark(String step) => _quietly(() {
    final text = step.toJString();
    _mark.call(_class, jvoid.type, [androidApplicationContext, text]);
    text.release();
  });

  @override
  String? takeStalled() => _quietly<String?>(
    () => _takeStalled
        .callNullable(_class, JString.type, [androidApplicationContext])
        ?.toDartString(releaseOriginal: true),
  );
}

/// iOS: the Swift class `MushafiStartupTrace`, through the Objective-C
/// runtime.
final class _ObjCStartupTrace implements StartupTrace {
  late final objc.ObjectPtr _class = objc.getClass('MushafiStartupTrace');
  late final Pointer<objc.ObjCSelector> _mark = objc.registerName('mark:');
  late final Pointer<objc.ObjCSelector> _takeStalled = objc.registerName(
    'takeStalled',
  );
  late final void Function(
    objc.ObjectPtr,
    Pointer<objc.ObjCSelector>,
    objc.ObjectPtr,
  )
  _send1 = objc.msgSendPointer
      .cast<
        NativeFunction<
          Void Function(
            objc.ObjectPtr,
            Pointer<objc.ObjCSelector>,
            objc.ObjectPtr,
          )
        >
      >()
      .asFunction();
  late final objc.ObjectPtr Function(objc.ObjectPtr, Pointer<objc.ObjCSelector>)
  _send0 = objc.msgSendPointer
      .cast<
        NativeFunction<
          objc.ObjectPtr Function(objc.ObjectPtr, Pointer<objc.ObjCSelector>)
        >
      >()
      .asFunction();

  @override
  void mark(String step) =>
      _quietly(() => _send1(_class, _mark, step.toNSString().ref.pointer));

  @override
  String? takeStalled() => _quietly<String?>(() {
    final result = _send0(_class, _takeStalled);
    if (result == nullptr) return null;
    return objc.NSString.fromPointer(
      result,
      retain: true,
      release: true,
    ).toDartString();
  });
}

/// Elsewhere (tests, desktop): nothing is noted.
final class _NoStartupTrace implements StartupTrace {
  const _NoStartupTrace();

  @override
  void mark(String step) {}

  @override
  String? takeStalled() => null;
}

/// The trace is only a diagnostic: if the native side cannot be reached, the
/// app goes on without it.
T? _quietly<T>(T Function() call) {
  try {
    return call();
  } on Object {
    return null;
  }
}
