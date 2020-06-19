import 'package:binary/binary.dart';

/// Whether `assert` function is executed in the current environment.
///
/// By default this will often be `true` in development and tests, and `false`
/// in production (apps and binaries), which makes it a useful tool for
/// conditional execution:
/// ```
/// if (assertionsEnabled) {
///   doLongButStrictlyUnnecessaryDebugCheck();
/// }
/// ```
bool get assertionsEnabled {
  var enabled = false;
  assert(enabled = true);
  return enabled;
}

extension IntX on int {
  /// Returns [intValue], asserting that it is the same as [checkBits].
  int check([String check]) {
    if (assertionsEnabled && check != null) {
      assert(
        this.toBinaryPadded(check.length) == check,
        ''
        'Expected 0x${int.parse(check, radix: 2).toRadixString(16)}, '
        'got 0x${this.toRadixString(16)}',
      );
    }
    return this;
  }
}
