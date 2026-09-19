import 'dart:io';

import 'package:path/path.dart' as p;

import 'command.dart';

/// Name of the directory holding files shared across all flavors.
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

/// The `web/` directory inside [projectRoot].
Directory webDirOf(Directory projectRoot) =>
    Directory(p.join(projectRoot.path, 'web'));

/// Available flavors: subdirectories of [flavorsDir], excluding `common/`.
List<String> listFlavors(Directory flavorsDir) {
  if (!flavorsDir.existsSync()) return const [];
  final names = <String>[];
  for (final entity in flavorsDir.listSync(followLinks: false)) {
    if (entity is Directory && p.basename(entity.path) != commonDirName) {
      names.add(p.basename(entity.path));
    }
  }
  names.sort();
  return names;
}

/// Deletes [webDir] if needed, then re-fabricates it from `common/` plus the
/// [flavor] overlay (the overlay wins on conflict).
///
/// Stale files can never persist: `web/` is always rebuilt from scratch.
/// Throws a [UsageException] for invalid input or project layout.
/// [log] receives non-fatal notes (e.g. a missing `common/` directory).
void fabricateWeb({
  required Directory flavorsDir,
  required Directory webDir,
  required String flavor,
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
      'No web-flavors/ directory at ${flavorsDir.path}.\n'
      'Create web-flavors/common/ and web-flavors/<flavor>/ first.',
    );
  }
  final flavorDir = Directory(p.join(flavorsDir.path, flavor));
  if (!flavorDir.existsSync()) {
    final available = listFlavors(flavorsDir);
    final hint = available.isEmpty
        ? 'No flavors found.'
        : 'Available flavors: ${available.join(', ')}.';
    throw UsageException(
      'Unknown flavor "$flavor" (no ${flavorDir.path}/ directory). $hint',
    );
  }

  if (webDir.existsSync()) webDir.deleteSync(recursive: true);
  webDir.createSync(recursive: true);

  final commonDir = Directory(p.join(flavorsDir.path, commonDirName));
  if (commonDir.existsSync()) {
    copyDirectory(commonDir, webDir);
  } else {
    (log ?? stderr.writeln)(
      'web_flavors: no ${commonDir.path}/ directory, using "$flavor" only.',
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
