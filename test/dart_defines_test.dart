import 'package:test/test.dart';
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

  group('WebAppFlavor', () {
    test('exposes the define key and current value', () {
      expect(WebAppFlavor.defineKey, 'WEB_APP_FLAVOR');
      expect(WebAppFlavor.current, isA<String>());
    });
  });
}
