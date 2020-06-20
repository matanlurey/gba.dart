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
