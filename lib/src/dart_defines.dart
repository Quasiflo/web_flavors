import 'package:web_flavors/src/command.dart';
import 'package:web_flavors/src/flavor_key.dart';

/// Appends `--dart-define=WEB_APP_FLAVOR=<flavor>` to [flutterArgs].
///
/// Throws a [UsageException] when the caller already passed a value for the
/// key: silently picking one side would desync the fabricated `web/` overlay
/// from what Dart code reads via `webAppFlavor`.
List<String> withFlavorDefine(final List<String> flutterArgs, final String flavor) {
  for (final arg in flutterArgs) {
    if (arg.contains('$flavorDefineKey=')) {
      throw UsageException(
        'flutter args already define $flavorDefineKey ("$arg"). '
        'Remove it; the wrapper injects --dart-define='
        '$flavorDefineKey=$flavor itself.',
      );
    }
  }
  return [...flutterArgs, '--dart-define=$flavorDefineKey=$flavor'];
}
