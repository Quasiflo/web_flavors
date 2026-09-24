import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:web_flavors/src/command.dart';
import 'package:web_flavors/src/config.dart';
import 'package:web_flavors/src/fabrication.dart';
import 'package:yaml/yaml.dart';

/// Standard pubspec key naming the flavor used when none is passed
/// (`flutter: default-flavor: <name>`).
const defaultFlavorKey = 'default-flavor';

/// The `flutter: default-flavor:` value from the pubspec.yaml in
/// [projectRoot], or `null` when absent.
///
/// Throws a [UsageException] when the file exists but cannot be parsed or
/// the value is not a usable string.
String? defaultFlavorFromPubspec(final Directory projectRoot) {
  final file = File(p.join(projectRoot.path, 'pubspec.yaml'));
  if (!file.existsSync()) {
    return null;
  }

  late final Object? document;
  try {
    document = loadYaml(file.readAsStringSync());
  } on FormatException catch (error) {
    throw UsageException(
      'Could not parse ${file.path} for the default flavor: '
      '${error.message}',
    );
  }
  if (document is! YamlMap) {
    return null;
  }
  final flutter = document['flutter'];
  if (flutter is! YamlMap) {
    return null;
  }
  final value = flutter[defaultFlavorKey];
  if (value == null) {
    return null;
  }
  if (value is! String || value.isEmpty) {
    throw UsageException(
      'Invalid `$defaultFlavorKey` in ${file.path}: '
      'expected a non-empty string.',
    );
  }
  return value;
}

/// Resolves the flavor to use: [explicit] wins, otherwise the pubspec
/// default, otherwise a [UsageException] listing available flavors.
///
/// Available flavors are listed from [config]'s container directory with
/// its prefix applied.
String resolveFlavor({
  required final String? explicit,
  required final Directory projectRoot,
  final WebFlavorsConfig config = WebFlavorsConfig.defaults,
}) {
  final flavor = explicit ?? defaultFlavorFromPubspec(projectRoot);
  if (flavor != null) {
    return flavor;
  }
  final container = containerDirOf(projectRoot, config);
  final available = visibleFlavors(
    container,
    webDirOf(projectRoot),
    config.flavorPrefix,
    config.commonDir,
  );
  final hint = available.isEmpty ? 'No flavors found.' : 'Available flavors: ${available.join(', ')}.';
  throw UsageException(
    'No <flavor> given and no `flutter: $defaultFlavorKey:` in pubspec.yaml. '
    '$hint',
  );
}
