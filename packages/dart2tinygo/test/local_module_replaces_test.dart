import 'dart:io';

import 'package:dart2tinygo/src/frontend/bindings.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// `localModuleReplacesOf` (#63): a binding's `go.mod` replaces another
/// binding's Go module with a workspace-relative path
/// (`../../tinygo_machine/go`). Under a pub cache the sibling package lives in
/// a version-suffixed directory (`tinygo_machine-0.0.2/go`), so the relative
/// path dangles and must be resolved against the cache instead.
void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('dart2tinygo_repl'));
  tearDown(() => root.deleteSync(recursive: true));

  GoLocalModule writeModule(String pkgDir, String modulePath,
      {String? replace}) {
    final goDir = Directory(p.join(root.path, pkgDir, 'go'))
      ..createSync(recursive: true);
    File(p.join(goDir.path, 'go.mod')).writeAsStringSync(
      'module $modulePath\n\ngo 1.21\n'
      '${replace == null ? '' : '\nreplace $replace\n'}',
    );
    return GoLocalModule(modulePath: modulePath, directory: goDir.path);
  }

  const dep = 'example.com/repo/packages/dep/go';
  const replace = '$dep => ../../dep/go';

  test('resolves a workspace-relative replace that exists as written', () {
    final dir = writeModule('packages/dep', dep);
    final module =
        writeModule('packages/binding', 'example.com/b/go', replace: replace);
    final found = localModuleReplacesOf(module);
    expect(found.single.modulePath, dep);
    expect(found.single.directory, dir.directory);
  });

  test('falls back to the version-suffixed pub-cache sibling', () {
    writeModule('cache/dep-0.0.1', dep);
    final newest = writeModule('cache/dep-0.0.10', dep);
    writeModule('cache/dep-0.0.2', dep);
    final module = writeModule('cache/binding-0.0.2', 'example.com/b/go',
        replace: replace);
    final found = localModuleReplacesOf(module);
    expect(found.single.modulePath, dep);
    expect(found.single.directory, newest.directory);
  });

  test('skips the replace when nothing resolves', () {
    final module = writeModule('cache/binding-0.0.2', 'example.com/b/go',
        replace: replace);
    expect(localModuleReplacesOf(module), isEmpty);
  });
}
