import 'dart:io';

import 'package:web_flavors/web_flavors.dart';

/// Fabricates `web/` for `<flavor>`, then runs `flutter` with the rest.
///
/// Usage: `web_flavors <flavor> -- <flutter args...>`
Future<void> main(List<String> args) async {
  if (isHelpRequest(args)) {
    stdout.write(usage);
    return;
  }
  try {
    final command = parseArgs(args);
    fabricateWeb(
      flavorsDir: flavorsDirOf(Directory.current),
      webDir: webDirOf(Directory.current),
      flavor: command.flavor,
    );
    final flutterArgs = withFlavorDefine(command.flutterArgs, command.flavor);
    final process = await Process.start(
      'flutter',
      flutterArgs,
      runInShell: true,
      mode: ProcessStartMode.inheritStdio,
    );
    exit(await process.exitCode);
  } on UsageException catch (error) {
    stderr.writeln('web_flavors: ${error.message}');
    stderr.write(usage);
    exit(error.exitCode);
  } on ProcessException catch (error) {
    stderr.writeln('web_flavors: failed to run flutter: ${error.message}');
    exit(1);
  }
}
