/// Flavor support for Flutter web, via a wrapper CLI that fabricates `web/`.
///
/// For reading the active flavor in app code, use the dedicated entry point
/// instead: `import 'package:web_flavors/flavor.dart';`
library;

export 'src/command.dart';
export 'src/config.dart';
export 'src/dart_defines.dart';
export 'src/default_flavor.dart';
export 'src/fabrication.dart';
export 'src/flavor_key.dart';
export 'src/version.dart';
