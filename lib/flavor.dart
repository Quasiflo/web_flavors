import 'src/flavor_key.dart';

const _rawWebAppFlavor = String.fromEnvironment(flavorDefineKey);

/// The active web flavor (e.g. `'dev'`).
///
/// This is `null` when the app was built or run without the `web_flavors`
/// wrapper, since only the wrapper injects the backing `--dart-define`.
const String? webAppFlavor = _rawWebAppFlavor == '' ? null : _rawWebAppFlavor;
