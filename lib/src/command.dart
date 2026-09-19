/// The exit code for command-line usage errors, per BSD sysexits.
const usageExitCode = 64;

/// An error caused by invalid CLI input or project layout.
///
/// The entrypoint prints [message] and exits with [exitCode].
class UsageException implements Exception {
  /// Creates a usage error with a human-readable [message].
  const UsageException(this.message, {this.exitCode = usageExitCode});

  /// Human-readable description of what went wrong.
  final String message;

  /// Process exit code the entrypoint should use.
  final int exitCode;

  @override
  String toString() => message;
}

/// A successfully parsed invocation.
class ParsedCommand {
  /// Creates a parsed invocation.
  const ParsedCommand({required this.flavor, required this.flutterArgs});

  /// Name of the `web-flavors/<flavor>/` directory to overlay.
  final String flavor;

  /// Args after `--`, forwarded verbatim to `flutter`.
  final List<String> flutterArgs;
}

/// CLI usage text, printed for `--help` and after usage errors.
const usage = '''
Flavor support for Flutter web.

WARNING: web/ is deleted and re-fabricated on every run. Never edit it by
hand and keep it gitignored. Edit web-flavors/common/ and
web-flavors/<flavor>/ instead.

Usage: web_flavors <flavor> -- <flutter args...>

  <flavor>  Name of a directory under web-flavors/ (e.g. dev, prod).
  --        Separates web_flavors args from args forwarded to flutter.

Examples:
  web_flavors dev -- build web
  web_flavors prod -- build web --wasm --release
  web_flavors dev -- run -d chrome

The wrapper copies web-flavors/common/ into web/, overlays
web-flavors/<flavor>/ on top, injects --dart-define=WEB_APP_FLAVOR=<flavor>,
then runs flutter with the remaining args. The exit code is flutter's.
''';

/// Whether [args] is a help request (`-h`/`--help` as the first arg).
bool isHelpRequest(List<String> args) =>
    args.isEmpty || args.first == '-h' || args.first == '--help';

/// Splits `web_flavors <flavor> -- <flutter args...>`.
///
/// Throws a [UsageException] when the flavor is missing or no `--`
/// separator is present. Callers should have handled [isHelpRequest] first.
ParsedCommand parseArgs(List<String> args) {
  final separator = args.indexOf('--');
  if (separator < 1) {
    throw const UsageException(
      'Missing <flavor> and `--` separator.\n'
      'Expected: web_flavors <flavor> -- <flutter args...>',
    );
  }
  final flavor = args.sublist(0, separator).join(' ');
  final flutterArgs = args.sublist(separator + 1);
  if (flutterArgs.isEmpty) {
    throw const UsageException('Missing <flutter args...> after `--`.');
  }
  return ParsedCommand(flavor: flavor, flutterArgs: flutterArgs);
}
