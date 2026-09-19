import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:web_flavors/web_flavors.dart';

void main() {
  group('isValidFlavorName', () {
    test('accepts simple names', () {
      expect(isValidFlavorName('dev'), isTrue);
      expect(isValidFlavorName('prod-eu_2'), isTrue);
    });

    test('rejects traversal and separators', () {
      expect(isValidFlavorName('..'), isFalse);
      expect(isValidFlavorName('../x'), isFalse);
      expect(isValidFlavorName('a/b'), isFalse);
      expect(isValidFlavorName(r'a\b'), isFalse);
      expect(isValidFlavorName(''), isFalse);
      expect(isValidFlavorName('-dev'), isFalse);
      expect(isValidFlavorName('has space'), isFalse);
    });
  });

  group('fabricateWeb', () {
    late Directory project;
    late Directory flavorsDir;
    late Directory webDir;

    setUp(() {
      project = Directory.systemTemp.createTempSync('web_flavors_test.');
      flavorsDir = Directory(p.join(project.path, 'web-flavors'))..createSync();
      webDir = Directory(p.join(project.path, 'web'));
      _writeFile(flavorsDir, 'common/index.html', 'common');
      _writeFile(flavorsDir, 'common/shared.js', 'shared');
      _writeFile(flavorsDir, 'dev/index.html', 'dev');
    });

    tearDown(() {
      if (project.existsSync()) project.deleteSync(recursive: true);
    });

    test('overlays flavor on top of common', () {
      fabricateWeb(flavorsDir: flavorsDir, webDir: webDir, flavor: 'dev');

      expect(webDir.childFile('index.html').readAsStringSync(), 'dev');
      expect(webDir.childFile('shared.js').readAsStringSync(), 'shared');
    });

    test('removes stale files from previous fabrications', () {
      webDir
        ..createSync(recursive: true)
        ..childFile('stale.txt').writeAsStringSync('stale');

      fabricateWeb(flavorsDir: flavorsDir, webDir: webDir, flavor: 'dev');

      expect(webDir.childFile('stale.txt').existsSync(), isFalse);
    });

    test('succeeds without common, keeping flavor files', () {
      Directory(p.join(flavorsDir.path, 'common')).deleteSync(recursive: true);
      final notes = <String>[];

      fabricateWeb(
        flavorsDir: flavorsDir,
        webDir: webDir,
        flavor: 'dev',
        log: notes.add,
      );

      expect(webDir.childFile('index.html').readAsStringSync(), 'dev');
      expect(notes, hasLength(1));
    });

    test('unknown flavor lists available flavors', () {
      expect(
        () => fabricateWeb(
          flavorsDir: flavorsDir,
          webDir: webDir,
          flavor: 'prod',
        ),
        throwsA(
          isA<UsageException>().having(
            (e) => e.message,
            'message',
            contains('dev'),
          ),
        ),
      );
    });

    test('invalid flavor name throws', () {
      expect(
        () => fabricateWeb(
          flavorsDir: flavorsDir,
          webDir: webDir,
          flavor: '../evil',
        ),
        throwsA(isA<UsageException>()),
      );
    });

    test('missing web-flavors directory throws', () {
      flavorsDir.deleteSync(recursive: true);

      expect(
        () => fabricateWeb(
          flavorsDir: flavorsDir,
          webDir: webDir,
          flavor: 'dev',
        ),
        throwsA(isA<UsageException>()),
      );
    });
  });

  group('listFlavors', () {
    test('excludes common and sorts', () {
      final project = Directory.systemTemp.createTempSync('web_flavors_test.');
      addTearDown(() => project.deleteSync(recursive: true));
      final flavors = Directory(p.join(project.path, 'web-flavors'))
        ..createSync();
      for (final name in ['prod', 'common', 'dev']) {
        Directory(p.join(flavors.path, name)).createSync();
      }

      expect(listFlavors(flavors), ['dev', 'prod']);
    });

    test('missing directory yields no flavors', () {
      expect(listFlavors(Directory('/does/not/exist')), isEmpty);
    });

    test('strips prefix and ignores the rest', () {
      final project = Directory.systemTemp.createTempSync('web_flavors_test.');
      addTearDown(() => project.deleteSync(recursive: true));
      final flavors = Directory(p.join(project.path, 'web-flavors'))
        ..createSync();
      for (final name in ['web-prod', 'web-common', 'web-', 'unrelated']) {
        Directory(p.join(flavors.path, name)).createSync();
      }

      expect(
        listFlavors(flavors, 'web-', 'web-common'),
        ['prod'],
      );
    });
  });

  group('fabricateWeb with prefix', () {
    late Directory project;
    late Directory flavorsDir;
    late Directory webDir;

    setUp(() {
      project = Directory.systemTemp.createTempSync('web_flavors_test.');
      flavorsDir = Directory(p.join(project.path, 'web-flavors'))..createSync();
      webDir = Directory(p.join(project.path, 'web'));
      _writeFile(flavorsDir, 'common/index.html', 'common');
      _writeFile(flavorsDir, 'web-dev/index.html', 'dev');
    });

    tearDown(() {
      if (project.existsSync()) project.deleteSync(recursive: true);
    });

    test('overlays the prefixed flavor on unprefixed common', () {
      fabricateWeb(
        flavorsDir: flavorsDir,
        webDir: webDir,
        flavor: 'dev',
        flavorPrefix: 'web-',
      );

      expect(webDir.childFile('index.html').readAsStringSync(), 'dev');
    });

    test('supports a custom common dir', () {
      _writeFile(flavorsDir, 'web-common/shared.js', 'shared');
      fabricateWeb(
        flavorsDir: flavorsDir,
        webDir: webDir,
        flavor: 'dev',
        flavorPrefix: 'web-',
        commonDir: 'web-common',
      );

      expect(webDir.childFile('index.html').readAsStringSync(), 'dev');
      expect(webDir.childFile('shared.js').readAsStringSync(), 'shared');
    });

    test('unknown flavor lists logical names', () {
      expect(
        () => fabricateWeb(
          flavorsDir: flavorsDir,
          webDir: webDir,
          flavor: 'prod',
          flavorPrefix: 'web-',
        ),
        throwsA(
          isA<UsageException>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('web-prod'),
              contains('Available flavors: dev'),
            ),
          ),
        ),
      );
    });
  });

  group('fabricateWeb at project root', () {
    test('generated web/ is not listed as a flavor', () {
      final project = Directory.systemTemp.createTempSync('web_flavors_test.');
      addTearDown(() => project.deleteSync(recursive: true));
      final webDir = Directory(p.join(project.path, 'web'))..createSync();

      expect(
        () => fabricateWeb(
          flavorsDir: project,
          webDir: webDir,
          flavor: 'dev',
        ),
        throwsA(
          isA<UsageException>().having(
            (e) => e.message,
            'message',
            contains('No flavors found.'),
          ),
        ),
      );
    });

    test('flavor resolving to the output directory throws', () {
      final project = Directory.systemTemp.createTempSync('web_flavors_test.');
      addTearDown(() => project.deleteSync(recursive: true));
      final webDir = Directory(p.join(project.path, 'web'))..createSync();

      expect(
        () => fabricateWeb(
          flavorsDir: project,
          webDir: webDir,
          flavor: 'web',
        ),
        throwsA(
          isA<UsageException>().having(
            (e) => e.message,
            'message',
            contains('output directory'),
          ),
        ),
      );
    });
  });
}

extension on Directory {
  File childFile(String name) => File(p.join(path, name));
}

void _writeFile(Directory flavorsDir, String relative, String content) {
  final file = File(p.join(flavorsDir.path, relative))
    ..createSync(recursive: true);
  file.writeAsStringSync(content);
}
