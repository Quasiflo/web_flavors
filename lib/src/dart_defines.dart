import 'command.dart';
import 'flavor_key.dart';

/// Appends `--dart-define=WEB_APP_FLAVOR=<flavor>` to [flutterArgs].
///
/// Throws a [UsageException] when the caller already passed a value for the
/// key: silently picking one side would desync the fabricated `web/` overlay
/// from what Dart code reads via `webAppFlavor`.
List<String> withFlavorDefine(List<String> flutterArgs, String flavor) {
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
