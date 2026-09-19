/// In-app access to the active web flavor.
///
///
/// The wrapper injects `--dart-define=WEB_APP_FLAVOR=<flavor>` into every
/// `flutter` invocation, so this is always populated when the app was built
/// or run through `web_flavors`. When the app was built directly with
/// `flutter` (no wrapper), [current] is `''`.
///
/// This helper is optional convenience. If you prefer to keep `web_flavors`
/// a dev-only dependency, read the value directly instead:
///
/// ```dart
/// const flavor = String.fromEnvironment('WEB_APP_FLAVOR');
/// ```
abstract final class WebAppFlavor {
  WebAppFlavor._();

  /// The `--dart-define` key the wrapper injects and [current] reads.
  static const defineKey = 'WEB_APP_FLAVOR';

  /// The active web flavor (e.g. `dev`, `prod`), or `''` if unset.
  static const current = String.fromEnvironment(defineKey);
}
