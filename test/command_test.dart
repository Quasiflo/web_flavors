import 'package:test/test.dart';
import 'package:web_flavors/web_flavors.dart';

void main() {
  group('parseWrapperArgs', () {
    test('splits flavor from flutter args', () {
      final command = parseWrapperArgs(['dev', '--', 'build', 'web', '--wasm']);
      expect(command.flavor, 'dev');
      expect(command.flutterArgs, ['build', 'web', '--wasm']);
      expect(command.showHelp, isFalse);
      expect(command.showVersion, isFalse);
    });

    test('flavor is optional', () {
      final command = parseWrapperArgs(['--', 'build', 'web']);
      expect(command.flavor, isNull);
      expect(command.flutterArgs, ['build', 'web']);
    });

    test('forwards all flutter flags verbatim', () {
      final command = parseWrapperArgs([
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

    test('--help and -h set showHelp without flutter args', () {
      expect(parseWrapperArgs(['--help']).showHelp, isTrue);
      expect(parseWrapperArgs(['-h']).showHelp, isTrue);
      expect(
        parseWrapperArgs(['dev', '--help', '--', 'build', 'web']).showHelp,
        isTrue,
      );
    });

    test('--version sets showVersion without flutter args', () {
      final command = parseWrapperArgs(['--version']);
      expect(command.showVersion, isTrue);
      expect(command.showHelp, isFalse);
    });

    test('throws when separator is missing', () {
      expect(
        () => parseWrapperArgs(['dev', 'build', 'web']),
        throwsA(isA<UsageException>()),
      );
    });

    test('throws when flutter args are missing', () {
      expect(
        () => parseWrapperArgs(['dev', '--']),
        throwsA(isA<UsageException>()),
      );
    });

    test('throws on more than one flavor operand', () {
      expect(
        () => parseWrapperArgs(['dev', 'prod', '--', 'build', 'web']),
        throwsA(isA<UsageException>()),
      );
    });

    test('throws on unknown wrapper flags', () {
      expect(
        () => parseWrapperArgs(['--frobnicate', '--', 'build', 'web']),
        throwsA(isA<UsageException>()),
      );
    });

    test('flutter args after -- are never parsed as wrapper flags', () {
      final command = parseWrapperArgs(['--', '--help']);
      expect(command.showHelp, isFalse);
      expect(command.flutterArgs, ['--help']);
    });
  });

  group('usage', () {
    test('mentions flavor, separator and flags', () {
      expect(usage, contains('[<flavor>]'));
      expect(usage, contains('--help'));
      expect(usage, contains('--version'));
    });
  });
}
