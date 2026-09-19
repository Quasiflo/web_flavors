import 'command.dart';
import 'web_app_flavor.dart';

/// Appends `--dart-define=WEB_APP_FLAVOR=<flavor>` to [flutterArgs].
///
/// Throws a [UsageException] when the caller already passed a value for the
/// key: silently picking one side would desync the fabricated `web/` overlay
/// from what Dart code reads via [WebAppFlavor].
List<String> withFlavorDefine(List<String> flutterArgs, String flavor) {
  for (final arg in flutterArgs) {
    if (arg.contains('${WebAppFlavor.defineKey}=')) {
      throw UsageException(
        'flutter args already define ${WebAppFlavor.defineKey} ("$arg"). '
        'Remove it; the wrapper injects --dart-define='
        '${WebAppFlavor.defineKey}=$flavor itself.',
      );
    }
  }
  return [...flutterArgs, '--dart-define=${WebAppFlavor.defineKey}=$flavor'];
}
