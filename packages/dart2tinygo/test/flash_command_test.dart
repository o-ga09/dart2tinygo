@Timeout(Duration(minutes: 2))
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// `dart2tinygo flash` (#26): argument handling and the missing-`tinygo`
/// error. No hardware in CI, so the happy path (an actual flash) is not
/// covered here — only that `flash` builds first and then hands off to
/// `tinygo flash`.
void main() {
  final entry = p.join('test', 'golden', 'minimal_blink.dart');

  Future<ProcessResult> runCli(List<String> args, {String? path}) {
    return Process.run(
      'dart',
      ['run', 'bin/dart2tinygo.dart', ...args],
      environment: path == null ? null : {'PATH': path},
    );
  }

  test('flash requires --target', () async {
    final tempDir = Directory.systemTemp.createTempSync('dart2tinygo_flash');
    addTearDown(() => tempDir.deleteSync(recursive: true));

    final result = await runCli([
      'flash',
      entry,
      '-o',
      p.join(tempDir.path, 'build'),
    ]);

    expect(result.exitCode, 64);
    expect(result.stderr, contains('--target=<tinygo-target>'));
  });

  test('flash requires exactly one entry argument', () async {
    final result = await runCli(['flash', '--target=wioterminal']);

    expect(result.exitCode, 64);
    expect(result.stderr, contains('expected exactly one <entry.dart>'));
  });

  test('flash builds, then fails with an install link when tinygo is '
      'missing from PATH', () async {
    final tempDir = Directory.systemTemp.createTempSync('dart2tinygo_flash');
    addTearDown(() => tempDir.deleteSync(recursive: true));
    final outDir = p.join(tempDir.path, 'build');

    // A PATH containing only the running Dart SDK's own bin directory: dart
    // itself is found (so `dart run` can execute the CLI), but tinygo is not
    // (nothing exercises real hardware).
    final dartOnlyPath = p.dirname(Platform.resolvedExecutable);

    final result = await runCli(
      ['flash', entry, '--target=wioterminal', '-o', outDir],
      path: dartOnlyPath,
    );

    expect(result.exitCode, 1);
    expect(
      result.stderr,
      contains('https://tinygo.org/getting-started/install/'),
    );
    expect(File(p.join(outDir, 'main.go')).existsSync(), isTrue);
    expect(File(p.join(outDir, 'go.mod')).existsSync(), isTrue);
  });
}
