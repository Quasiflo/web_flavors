import 'dart:io';

import 'package:path/path.dart' as p;

import 'command.dart';
import 'config.dart';

/// Name of the shared directory (before any configured prefix is applied).
const commonDirName = 'common';

/// Valid flavor names: letters, digits, `_` and `-`, starting alphanumerically.
///
/// This also blocks path traversal (`/`, `\`, `..`) by construction.
final RegExp flavorNamePattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]*$');

/// Whether [name] is usable as a flavor directory name.
bool isValidFlavorName(String name) => flavorNamePattern.hasMatch(name);

/// The `web-flavors/` directory inside [projectRoot].
Directory flavorsDirOf(Directory projectRoot) =>
    Directory(p.join(projectRoot.path, 'web-flavors'));

/// The flavors container: [config]'s `flavors-dir` under [projectRoot],
/// or [projectRoot] itself when flavors live at the workspace root.
Directory containerDirOf(
  Directory projectRoot, [
  WebFlavorsConfig config = WebFlavorsConfig.defaults,
]) {
  final dir = config.flavorsDir;
  if (dir == null) return projectRoot;
  return Directory(p.join(projectRoot.path, dir));
}

/// The `web/` directory inside [projectRoot].
Directory webDirOf(Directory projectRoot) =>
    Directory(p.join(projectRoot.path, 'web'));

/// Available flavors: subdirectories of [flavorsDir] matching
/// [flavorPrefix], with the prefix stripped and the shared directory
/// ([commonDir], prefix not applied) excluded.
List<String> listFlavors(
  Directory flavorsDir, [
  String flavorPrefix = '',
  String commonDir = commonDirName,
]) {
  if (!flavorsDir.existsSync()) return const [];
  final names = <String>[];
  for (final entity in flavorsDir.listSync(followLinks: false)) {
    if (entity is! Directory) continue;
    final dirname = p.basename(entity.path);
    if (dirname == commonDir) continue;
    if (!dirname.startsWith(flavorPrefix)) continue;
    final logical = dirname.substring(flavorPrefix.length);
    if (logical.isEmpty || !isValidFlavorName(logical)) {
      continue;
    }
    names.add(logical);
  }
  names.sort();
  return names;
}

/// Flavor names visible in [flavorsDir], excluding [outputDir] when it lives
/// directly inside (root mode would otherwise list the generated `web/`).
Iterable<String> visibleFlavors(
  Directory flavorsDir,
  Directory outputDir, [
  String flavorPrefix = '',
  String commonDir = commonDirName,
]) {
  final nested = p.equals(p.dirname(outputDir.path), flavorsDir.path);
  final outputName = p.basename(outputDir.path);
  return listFlavors(flavorsDir, flavorPrefix, commonDir).where(
    (name) => !(nested && name == outputName),
  );
}

/// Deletes [webDir] if needed, then re-fabricates it from the shared
/// directory plus the [flavor] overlay (the overlay wins on conflict).
///
/// Flavor directories are resolved inside [flavorsDir] with [flavorPrefix]
/// applied (`web-staging/` with prefix `web-` is flavor `staging`); the
/// shared directory is [commonDir] verbatim, prefix not applied.
///
/// Stale files can never persist: `web/` is always rebuilt from scratch.
/// Throws a [UsageException] for invalid input or project layout.
/// [log] receives non-fatal notes (e.g. a missing shared directory).
void fabricateWeb({
  required Directory flavorsDir,
  required Directory webDir,
  required String flavor,
  String flavorPrefix = '',
  String commonDir = commonDirName,
  void Function(String message)? log,
}) {
  if (!isValidFlavorName(flavor)) {
    throw UsageException(
      'Invalid flavor name "$flavor". '
      'Use letters, digits, "_" and "-", starting alphanumerically.',
    );
  }
  if (!flavorsDir.existsSync()) {
    throw UsageException(
      'No flavors directory at ${flavorsDir.path}.\n'
      'Create it with a shared "$commonDir/" directory '
      'and one "$flavorPrefix<flavor>/" directory per flavor first.',
    );
  }
  final flavorDir = Directory(p.join(flavorsDir.path, '$flavorPrefix$flavor'));
  if (p.equals(flavorDir.path, webDir.path)) {
    throw UsageException(
      'Flavor "$flavor" resolves to the output directory ${webDir.path}. '
      'Rename the flavor or configure a `flavor-prefix`.',
    );
  }
  if (!flavorDir.existsSync()) {
    final available = visibleFlavors(
      flavorsDir,
      webDir,
      flavorPrefix,
      commonDir,
    );
    final hint = available.isEmpty
        ? 'No flavors found.'
        : 'Available flavors: ${available.join(', ')}.';
    throw UsageException(
      'Unknown flavor "$flavor" (no ${flavorDir.path}/ directory). $hint',
    );
  }

  if (webDir.existsSync()) webDir.deleteSync(recursive: true);
  webDir.createSync(recursive: true);

  final sharedDir = Directory(p.join(flavorsDir.path, commonDir));
  if (sharedDir.existsSync()) {
    copyDirectory(sharedDir, webDir);
  } else {
    (log ?? stderr.writeln)(
      'web_flavors: no ${sharedDir.path}/ directory, using "$flavor" only.',
    );
  }
  copyDirectory(flavorDir, webDir);
}

/// Recursively copies [source] into [destination], overwriting conflicts.
void copyDirectory(Directory source, Directory destination) {
  for (final entity in source.listSync(recursive: true, followLinks: false)) {
    final relative = p.relative(entity.path, from: source.path);
    final target = p.join(destination.path, relative);
    if (entity is Directory) {
      Directory(target).createSync(recursive: true);
    } else if (entity is File) {
      File(target)
        ..createSync(recursive: true)
        ..writeAsBytesSync(entity.readAsBytesSync());
    } else if (entity is Link) {
      Link(target).createSync(entity.targetSync(), recursive: true);
    }
  }
}
