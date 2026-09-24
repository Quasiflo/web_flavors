import 'dart:io';

import 'package:web_flavors/web_flavors.dart';

/// Fabricates `web/` for the flavor, then runs `flutter` with the rest.
///
/// Usage: `web_flavors [<flavor>] [options] -- <flutter args...>`
Future<void> main(final List<String> args) async {
  try {
    final command = parseWrapperArgs(args);
    if (command.showHelp) {
      stdout.write(usage);
      return;
    }
    if (command.showVersion) {
      stdout.writeln(packageVersion);
      return;
    }
    final projectRoot = Directory.current;
    final config = WebFlavorsConfig.fromPubspec(projectRoot);
    final flavor = resolveFlavor(
      explicit: command.flavor,
      projectRoot: projectRoot,
      config: config,
    );
    fabricateWeb(
      flavorsDir: containerDirOf(projectRoot, config),
      webDir: webDirOf(projectRoot),
      flavor: flavor,
      flavorPrefix: config.flavorPrefix,
      commonDir: config.commonDir,
    );
    final flutterArgs = withFlavorDefine(command.flutterArgs, flavor);
    final process = await Process.start(
      'flutter',
      flutterArgs,
      runInShell: true,
      mode: ProcessStartMode.inheritStdio,
    );
    exit(await process.exitCode);
  } on UsageException catch (error) {
    stderr
      ..writeln('web_flavors: ${error.message}')
      ..write(usage);
    exit(error.exitCode);
  } on ProcessException catch (error) {
    stderr.writeln('web_flavors: failed to run flutter: ${error.message}');
    exit(1);
  }
}
