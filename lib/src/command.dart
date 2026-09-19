import 'package:args/args.dart' as args;

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

/// Parser for the wrapper's own args (everything before `--`).
final args.ArgParser wrapperArgParser = args.ArgParser()
  ..addFlag(
    'help',
    abbr: 'h',
    negatable: false,
    help: 'Print this usage text and exit.',
  )
  ..addFlag(
    'version',
    negatable: false,
    help: 'Print the web_flavors package version and exit.',
  );

/// A successfully parsed invocation.
class WrapperCommand {
  /// Creates a parsed invocation.
  const WrapperCommand({
    required this.flavor,
    required this.flutterArgs,
    required this.showHelp,
    required this.showVersion,
  });

  /// Explicit `<flavor>` operand, or `null` to use the pubspec default.
  final String? flavor;

  /// Args after `--`, forwarded verbatim to `flutter`.
  final List<String> flutterArgs;

  /// Whether `--help` was passed.
  final bool showHelp;

  /// Whether `--version` was passed.
  final bool showVersion;
}

/// CLI usage text, printed for `--help` and after usage errors.
String get usage => '''
Flavor support for Flutter web.

WARNING: web/ is deleted and re-fabricated on every run. Never edit it by
hand and keep it gitignored. Edit web-flavors/common/ and
web-flavors/<flavor>/ instead.

Usage: web_flavors [<flavor>] [options] -- <flutter args...>

  <flavor>  Name of a directory under web-flavors/ (e.g. dev, prod).
            When omitted, the `flutter: default-flavor:` value from the
            project's pubspec.yaml is used.
  --        Separates web_flavors args from args forwarded to flutter.

Examples:
  web_flavors dev -- build web
  web_flavors -- build web
  web_flavors prod -- build web --wasm --release
  web_flavors dev -- run -d chrome

${wrapperArgParser.usage}
The wrapper copies web-flavors/common/ into web/, overlays
web-flavors/<flavor>/ on top, injects --dart-define=WEB_APP_FLAVOR=<flavor>,
then runs flutter with the remaining args. The exit code is flutter's.
''';

/// Splits `web_flavors [<flavor>] [options] -- <flutter args...>`.
/// (`package:args` types are prefixed with `args` to avoid clashing with
/// this library's own [UsageException].)
///
/// Throws a [UsageException] when wrapper flags are invalid, more than one
/// flavor operand is given, or (for non-help/version requests) no `--`
/// separator with flutter args is present.
WrapperCommand parseWrapperArgs(List<String> argv) {
  final separator = argv.indexOf('--');
  final head = separator == -1 ? argv : argv.sublist(0, separator);
  final flutterArgs = separator == -1
      ? const <String>[]
      : argv.sublist(
          separator + 1,
        );

  late final args.ArgResults results;
  try {
    results = wrapperArgParser.parse(head);
  } on FormatException catch (error) {
    throw UsageException(error.message);
  }

  final operands = results.rest;
  if (operands.length > 1) {
    throw const UsageException(
      'Expected at most one <flavor> before `--`.\n'
      'Usage: web_flavors [<flavor>] [options] -- <flutter args...>',
    );
  }

  final showHelp = results.flag('help');
  final showVersion = results.flag('version');
  if (!showHelp && !showVersion && flutterArgs.isEmpty) {
    throw const UsageException(
      'Missing `--` separator and <flutter args...>.\n'
      'Usage: web_flavors [<flavor>] [options] -- <flutter args...>',
    );
  }
  return WrapperCommand(
    flavor: operands.isEmpty ? null : operands.single,
    flutterArgs: flutterArgs,
    showHelp: showHelp,
    showVersion: showVersion,
  );
}
