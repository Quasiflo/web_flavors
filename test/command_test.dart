import 'package:test/test.dart';
import 'package:web_flavors/web_flavors.dart';

void main() {
  group('isHelpRequest', () {
    test('empty args request help', () {
      expect(isHelpRequest([]), isTrue);
    });

    test('-h and --help request help', () {
      expect(isHelpRequest(['-h']), isTrue);
      expect(isHelpRequest(['--help']), isTrue);
    });

    test('flavor does not request help', () {
      expect(isHelpRequest(['dev', '--', 'build', 'web']), isFalse);
    });
  });

  group('parseArgs', () {
    test('splits flavor from flutter args', () {
      final command = parseArgs(['dev', '--', 'build', 'web', '--wasm']);
      expect(command.flavor, 'dev');
      expect(command.flutterArgs, ['build', 'web', '--wasm']);
    });

    test('forwards all flutter flags verbatim', () {
      final command = parseArgs([
        'prod',
        '--',
        'run',
        '-d',
        'chrome',
        '--dart-define=API=https://x',
      ]);
      expect(command.flutterArgs, [
        'run',
        '-d',
        'chrome',
        '--dart-define=API=https://x',
      ]);
    });

    test('throws when separator is missing', () {
      expect(
        () => parseArgs(['dev', 'build', 'web']),
        throwsA(isA<UsageException>()),
      );
    });

    test('throws when flavor is missing', () {
      expect(() => parseArgs(['--', 'build', 'web']),
          throwsA(isA<UsageException>()));
    });

    test('throws when flutter args are missing', () {
      expect(() => parseArgs(['dev', '--']), throwsA(isA<UsageException>()));
    });
  });
}
