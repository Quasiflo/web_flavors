import 'package:web_flavors/src/flavor_key.dart';

// This is the intended use of `String.fromEnvironment`: reading the
// `--dart-define` injected by the wrapper.
// ignore: do_not_use_environment
const _rawWebAppFlavor = String.fromEnvironment(flavorDefineKey);

/// The active web flavor (e.g. `'dev'`).
///
/// This is `null` when the app was built or run without the `web_flavors`
/// wrapper, since only the wrapper injects the backing `--dart-define`.
const String? webAppFlavor = _rawWebAppFlavor == '' ? null : _rawWebAppFlavor;
