import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:web_flavors/web_flavors.dart';

void main() {
  group('defaultFlavorFromPubspec', () {
    late Directory project;

    setUp(() {
      project = Directory.systemTemp.createTempSync('web_flavors_test.');
    });

    tearDown(() {
      if (project.existsSync()) {
        project.deleteSync(recursive: true);
      }
    });

    test('reads flutter: default-flavor', () {
      _writePubspec(
        project,
        'name: demo\nflutter:\n  default-flavor: prod\n',
      );
      expect(defaultFlavorFromPubspec(project), 'prod');
    });

    test('null without pubspec.yaml', () {
      expect(defaultFlavorFromPubspec(project), isNull);
    });

    test('null without flutter section', () {
      _writePubspec(project, 'name: demo\n');
      expect(defaultFlavorFromPubspec(project), isNull);
    });

    test('null without default-flavor key', () {
      _writePubspec(
        project,
        'name: demo\nflutter:\n  uses-material-design: true\n',
      );
      expect(defaultFlavorFromPubspec(project), isNull);
    });

    test('throws on non-string value', () {
      _writePubspec(
        project,
        'name: demo\nflutter:\n  default-flavor: 42\n',
      );
      expect(
        () => defaultFlavorFromPubspec(project),
        throwsA(isA<UsageException>()),
      );
    });

    test('throws on malformed yaml', () {
      _writePubspec(project, 'flutter: [unclosed\n');
      expect(
        () => defaultFlavorFromPubspec(project),
        throwsA(isA<UsageException>()),
      );
    });
  });

  group('resolveFlavor', () {
    late Directory project;

    setUp(() {
      project = Directory.systemTemp.createTempSync('web_flavors_test.');
      Directory(p.join(project.path, 'web-flavors', 'dev')).createSync(
        recursive: true,
      );
    });

    tearDown(() {
      if (project.existsSync()) {
        project.deleteSync(recursive: true);
      }
    });

    test('explicit flavor wins over pubspec default', () {
      _writePubspec(
        project,
        'name: demo\nflutter:\n  default-flavor: prod\n',
      );
      expect(
        resolveFlavor(explicit: 'dev', projectRoot: project),
        'dev',
      );
    });

    test('falls back to pubspec default', () {
      _writePubspec(
        project,
        'name: demo\nflutter:\n  default-flavor: prod\n',
      );
      expect(resolveFlavor(explicit: null, projectRoot: project), 'prod');
    });

    test('throws listing available flavors when neither exists', () {
      expect(
        () => resolveFlavor(explicit: null, projectRoot: project),
        throwsA(
          isA<UsageException>().having(
            (final e) => e.message,
            'message',
            contains('dev'),
          ),
        ),
      );
    });

    test('lists logical names with prefix at root', () {
      _writePubspec(
        project,
        'name: demo\nweb_flavors:\n'
        '  flavors-dir:\n'
        '  flavor-prefix: web-\n',
      );
      Directory(p.join(project.path, 'web-staging')).createSync();
      final config = WebFlavorsConfig.fromPubspec(project);

      expect(
        () => resolveFlavor(
          explicit: null,
          projectRoot: project,
          config: config,
        ),
        throwsA(
          isA<UsageException>().having(
            (final e) => e.message,
            'message',
            allOf(contains('staging'), isNot(contains('web-staging'))),
          ),
        ),
      );
    });
  });
}

void _writePubspec(final Directory project, final String content) {
  File(p.join(project.path, 'pubspec.yaml')).writeAsStringSync(content);
}
