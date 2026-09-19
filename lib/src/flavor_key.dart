/// The `--dart-define` key the wrapper injects and `webAppFlavor` reads.
///
/// Single source of truth, shared by the CLI injector and the `flavor.dart`
/// entry point (which imports this without re-exporting it).
const flavorDefineKey = 'WEB_APP_FLAVOR';
