import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:web_flavors/web_flavors.dart';

void main() {
  group('WebFlavorsConfig.fromPubspec', () {
    late Directory project;

    setUp(() {
      project = Directory.systemTemp.createTempSync('web_flavors_test.');
    });

    tearDown(() {
      if (project.existsSync()) {
        project.deleteSync(recursive: true);
      }
    });

    test('defaults without pubspec.yaml', () {
      final config = WebFlavorsConfig.fromPubspec(project);
      expect(config.flavorsDir, 'web-flavors');
      expect(config.flavorPrefix, isEmpty);
    });

    test('defaults without web_flavors section', () {
      _writePubspec(project, 'name: demo\n');
      expect(
        WebFlavorsConfig.fromPubspec(project),
        _isDefaults,
      );
    });

    test('defaults with null section', () {
      _writePubspec(project, 'name: demo\nweb_flavors:\n');
      expect(
        WebFlavorsConfig.fromPubspec(project),
        _isDefaults,
      );
    });

    test('custom directory, prefix and common dir', () {
      _writePubspec(
        project,
        'name: demo\nweb_flavors:\n'
        '  flavors-dir: tool/flavors\n'
        '  flavor-prefix: web-\n'
        '  common-dir: web-common\n',
      );
      final config = WebFlavorsConfig.fromPubspec(project);
      expect(config.flavorsDir, p.join('tool', 'flavors'));
      expect(config.flavorPrefix, 'web-');
      expect(config.commonDir, 'web-common');
    });

    test('only null means the project root', () {
      for (final value in ['null', '~']) {
        _writePubspec(
          project,
          'name: demo\nweb_flavors:\n  flavors-dir: $value\n',
        );
        expect(
          WebFlavorsConfig.fromPubspec(project).flavorsDir,
          isNull,
          reason: 'flavors-dir: $value',
        );
      }
    });

    test('dot means the project root', () {
      _writePubspec(
        project,
        'name: demo\nweb_flavors:\n  flavors-dir: .\n',
      );
      expect(
        WebFlavorsConfig.fromPubspec(project).flavorsDir,
        isNull,
      );
    });

    test('throws on non-mapping section', () {
      _writePubspec(project, 'name: demo\nweb_flavors: [oops]\n');
      expect(
        () => WebFlavorsConfig.fromPubspec(project),
        throwsA(isA<UsageException>()),
      );
    });

    test('throws on unknown keys', () {
      _writePubspec(
        project,
        'name: demo\nweb_flavors:\n  flavour-dir: x\n',
      );
      expect(
        () => WebFlavorsConfig.fromPubspec(project),
        throwsA(
          isA<UsageException>().having(
            (final e) => e.message,
            'message',
            contains('flavors-dir'),
          ),
        ),
      );
    });

    test('throws on invalid flavors-dir values', () {
      for (final value in [
        '42',
        'true',
        'false',
        "''",
        "'/abs'",
        "'../escape'",
      ]) {
        _writePubspec(
          project,
          'name: demo\nweb_flavors:\n  flavors-dir: $value\n',
        );
        expect(
          () => WebFlavorsConfig.fromPubspec(project),
          throwsA(isA<UsageException>()),
          reason: 'flavors-dir: $value',
        );
      }
    });

    test('throws on invalid flavor-prefix values', () {
      for (final value in ['42', 'true', "'a/b'", r"'a\b'"]) {
        _writePubspec(
          project,
          'name: demo\nweb_flavors:\n  flavor-prefix: $value\n',
        );
        expect(
          () => WebFlavorsConfig.fromPubspec(project),
          throwsA(isA<UsageException>()),
          reason: 'flavor-prefix: $value',
        );
      }
    });

    test('throws on invalid common-dir values', () {
      for (final value in ['42', 'true', "''", "'a/b'", r"'a\b'"]) {
        _writePubspec(
          project,
          'name: demo\nweb_flavors:\n  common-dir: $value\n',
        );
        expect(
          () => WebFlavorsConfig.fromPubspec(project),
          throwsA(isA<UsageException>()),
          reason: 'common-dir: $value',
        );
      }
    });

    test('throws on malformed yaml', () {
      _writePubspec(project, 'web_flavors: [unclosed\n');
      expect(
        () => WebFlavorsConfig.fromPubspec(project),
        throwsA(isA<UsageException>()),
      );
    });
  });

  group('containerDirOf', () {
    test('resolves custom and root containers', () {
      final project = Directory('/proj');
      expect(
        containerDirOf(project).path,
        p.join('/proj', 'web-flavors'),
      );
      expect(
        containerDirOf(
          project,
          const WebFlavorsConfig(
            flavorsDir: 'tool/f',
            flavorPrefix: '',
            commonDir: 'common',
          ),
        ).path,
        p.join('/proj', 'tool', 'f'),
      );
      expect(
        containerDirOf(
          project,
          const WebFlavorsConfig(
            flavorsDir: null,
            flavorPrefix: 'web-',
            commonDir: 'web-common',
          ),
        ).path,
        project.path,
      );
    });
  });
}

final Matcher _isDefaults = isA<WebFlavorsConfig>().having((final c) => c.flavorsDir, 'flavorsDir', 'web-flavors').having((final c) => c.flavorPrefix, 'flavorPrefix', isEmpty).having((final c) => c.commonDir, 'commonDir', 'common');

void _writePubspec(final Directory project, final String content) {
  File(p.join(project.path, 'pubspec.yaml')).writeAsStringSync(content);
}
