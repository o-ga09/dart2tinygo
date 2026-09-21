@Timeout(Duration(minutes: 2))
library;

import 'dart:io';

import 'package:dart2tinygo/src/backend/generator.dart';
import 'package:dart2tinygo/src/checker/checker.dart';
import 'package:dart2tinygo/src/frontend/resolve.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Golden tests per `CONTRIBUTING.md`: each `<case>.dart` under
/// `test/golden/` must convert to exactly the paired `<case>.go`.
///
/// Set `UPDATE_GOLDENS=1` to rewrite the `.go` files from the current
/// generator output instead of asserting against them.
void main() {
  final goldenDir = Directory(p.join('test', 'golden'));
  final cases = goldenDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .map((f) => p.basenameWithoutExtension(f.path))
      .toList()
    ..sort();

  final updateGoldens = Platform.environment['UPDATE_GOLDENS'] == '1';

  for (final name in cases) {
    test('golden: $name', () async {
      final dartPath = p.join(goldenDir.path, '$name.dart');
      final goPath = p.join(goldenDir.path, '$name.go');

      final result = await resolveEntryPoint(dartPath);
      final errors = checkEntryPoint(result);
      expect(
        errors,
        isEmpty,
        reason: 'unexpected unsupported syntax in golden case "$name":\n'
            '${errors.join('\n')}',
      );

      final generated = generateGoFile(result).source;
      final formatted = await _gofmt(generated);

      if (updateGoldens) {
        File(goPath).writeAsStringSync(formatted);
        return;
      }

      final expected = File(goPath).readAsStringSync();
      expect(formatted, expected);
    });
  }
}

Future<String> _gofmt(String source) async {
  final process = await Process.start('gofmt', []);
  process.stdin.write(source);
  await process.stdin.close();
  final stdout =
      await process.stdout.transform(const SystemEncoding().decoder).join();
  final code = await process.exitCode;
  if (code != 0) {
    throw StateError('gofmt failed with exit code $code');
  }
  return stdout;
}
