import 'package:test/test.dart';
import 'package:web_flavors/flavor.dart';
import 'package:web_flavors/web_flavors.dart';

void main() {
  group('withFlavorDefine', () {
    test('appends the flavor define', () {
      expect(
        withFlavorDefine(['build', 'web'], 'dev'),
        ['build', 'web', '--dart-define=WEB_APP_FLAVOR=dev'],
      );
    });

    test('throws on --dart-define collision', () {
      expect(
        () => withFlavorDefine(
          ['build', 'web', '--dart-define=WEB_APP_FLAVOR=prod'],
          'dev',
        ),
        throwsA(isA<UsageException>()),
      );
    });

    test('throws on space-separated define collision', () {
      expect(
        () => withFlavorDefine(
          ['build', 'web', '--dart-define', 'WEB_APP_FLAVOR=prod'],
          'dev',
        ),
        throwsA(isA<UsageException>()),
      );
    });

    test('ignores unrelated defines', () {
      expect(
        withFlavorDefine(['build', 'web', '--dart-define=API=x'], 'dev'),
        [
          'build',
          'web',
          '--dart-define=API=x',
          '--dart-define=WEB_APP_FLAVOR=dev',
        ],
      );
    });
  });

  group('webAppFlavor', () {
    test('is null when no flavor was injected', () {
      // Tests run without --dart-define, so the flavor is unset.
      expect(webAppFlavor, isNull);
    });

    test('define key matches the injected key', () {
      expect(flavorDefineKey, 'WEB_APP_FLAVOR');
    });
  });

  group('packageVersion', () {
    test('looks like a version', () {
      expect(packageVersion, matches(RegExp(r'^\d+\.\d+\.\d+')));
    });
  });
}
