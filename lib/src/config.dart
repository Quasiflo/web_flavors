import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'command.dart';

/// Pubspec section holding wrapper configuration (`web_flavors:`).
const configKey = 'web_flavors';

/// Config key for the flavors container directory (`flavors-dir:`).
const flavorsDirKey = 'flavors-dir';

/// Config key for the flavor directory prefix (`flavor-prefix:`).
const flavorPrefixKey = 'flavor-prefix';

/// Config key for the shared directory name (`common-dir:`).
const commonDirKey = 'common-dir';

/// Wrapper configuration, read from the project's pubspec.yaml.
///
/// ```yaml
/// web_flavors:
///   flavors-dir: web-flavors # default; null means the project root
///   flavor-prefix: web- # default ''; `web-staging/` means flavor `staging`
///   common-dir: common # default; shared directory name, prefix not applied
/// ```
class WebFlavorsConfig {
  /// Creates a configuration.
  const WebFlavorsConfig({
    required this.flavorsDir,
    required this.flavorPrefix,
    required this.commonDir,
  });

  /// Configuration used when the project has no `web_flavors:` section.
  static const defaults = WebFlavorsConfig(
    flavorsDir: 'web-flavors',
    flavorPrefix: '',
    commonDir: 'common',
  );

  /// Container directory, relative to the project root, or `null` to keep
  /// flavor directories directly at the project root.
  final String? flavorsDir;

  /// Prefix stripped from directory names to get flavor names
  /// (`web-staging/` with prefix `web-` is flavor `staging`).
  /// Not applied to the shared directory (see [commonDir]).
  final String flavorPrefix;

  /// Name of the shared directory inside the container.
  final String commonDir;

  /// Reads the `web_flavors:` section from the pubspec.yaml in
  /// [projectRoot], merged over [defaults].
  ///
  /// Throws a [UsageException] when the section exists but is invalid.
  static WebFlavorsConfig fromPubspec(Directory projectRoot) {
    final file = File(p.join(projectRoot.path, 'pubspec.yaml'));
    if (!file.existsSync()) return defaults;

    late final Object? document;
    try {
      document = loadYaml(file.readAsStringSync());
    } on FormatException catch (error) {
      throw UsageException(
        'Could not parse ${file.path} for $configKey configuration: '
        '${error.message}',
      );
    }
    if (document is! YamlMap) {
      throw UsageException(
        'Could not parse ${file.path}: expected a mapping.',
      );
    }
    final section = document[configKey];
    if (section == null) return defaults;
    if (section is! YamlMap) {
      throw UsageException(
        'Invalid `$configKey` in ${file.path}: expected a mapping.',
      );
    }
    for (final key in section.keys) {
      if (key != flavorsDirKey &&
          key != flavorPrefixKey &&
          key != commonDirKey) {
        throw UsageException(
          'Unknown `$configKey` key "$key" in ${file.path}: '
          'expected `$flavorsDirKey`, `$flavorPrefixKey` '
          'and/or `$commonDirKey`.',
        );
      }
    }
    return WebFlavorsConfig(
      flavorsDir: _parseFlavorsDir(section[flavorsDirKey], file.path),
      flavorPrefix: _parseFlavorPrefix(section[flavorPrefixKey], file.path),
      commonDir: _parseCommonDir(section[commonDirKey], file.path),
    );
  }

  static String? _parseFlavorsDir(Object? value, String pubspecPath) {
    if (value == null) return null;
    if (value is String) {
      if (value.isEmpty) {
        throw UsageException(
          'Invalid `$flavorsDirKey` in $pubspecPath: '
          'expected a directory path, or null for the project root.',
        );
      }
      final normalized = p.normalize(value);
      if (normalized == '.') return null;
      if (p.isAbsolute(value) || normalized.startsWith('..')) {
        throw UsageException(
          'Invalid `$flavorsDirKey` "$value" in $pubspecPath: '
          'expected a directory inside the project.',
        );
      }
      return normalized;
    }
    throw UsageException(
      'Invalid `$flavorsDirKey` in $pubspecPath: '
      'expected a directory path, or null for the project root.',
    );
  }

  static String _parseFlavorPrefix(Object? value, String pubspecPath) {
    if (value == null) return defaults.flavorPrefix;
    if (value is! String || value.contains('/') || value.contains(r'\')) {
      throw UsageException(
        'Invalid `$flavorPrefixKey` in $pubspecPath: '
        'expected a plain name prefix such as "web-".',
      );
    }
    return value;
  }

  static String _parseCommonDir(Object? value, String pubspecPath) {
    if (value == null) return defaults.commonDir;
    if (value is! String ||
        value.isEmpty ||
        value.contains('/') ||
        value.contains(r'\')) {
      throw UsageException(
        'Invalid `$commonDirKey` in $pubspecPath: '
        'expected a plain directory name such as "common".',
      );
    }
    return value;
  }
}
