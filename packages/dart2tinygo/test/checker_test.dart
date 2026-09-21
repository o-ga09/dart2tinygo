import 'dart:io';

import 'package:dart2tinygo/src/checker/checker.dart';
import 'package:dart2tinygo/src/frontend/resolve.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Unsupported-syntax cases must be reported with file, line, and reason
/// (`CLAUDE.md`: "Unsupported syntax should be detected and reported up
/// front ... by the checker, not discovered mid-conversion").
void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('dart2tinygo_checker_test');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  Future<List<UnsupportedSyntaxError>> checkSource(String source) async {
    final path = p.join(tempDir.path, 'entry.dart');
    File(path).writeAsStringSync(source);
    final result = await resolveEntryPoint(path);
    return checkEntryPoint(result);
  }

  /// Like [checkSource], but the file lives inside this package so
  /// `package:test_binding` (a dev dependency) resolves.
  late Directory inPackageDir;

  setUp(() {
    inPackageDir = Directory(p.join('test', '.tmp'))
      ..createSync(recursive: true);
    inPackageDir = inPackageDir.createTempSync('checker_test');
  });

  tearDown(() {
    inPackageDir.deleteSync(recursive: true);
  });

  Future<List<UnsupportedSyntaxError>> checkBindingSource(
    String source,
  ) async {
    final path = p.join(inPackageDir.path, 'entry.dart');
    File(path).writeAsStringSync(source);
    final result = await resolveEntryPoint(path);
    return checkEntryPoint(result);
  }

  test('accepts the v0.1 minimal subset', () async {
    final errors = await checkSource('''
import 'dart:io';

void main() {
  var count = 0;
  while (true) {
    count++;
    print('blink \$count');
    sleep(const Duration(milliseconds: 500));
  }
}
''');
    expect(errors, isEmpty);
  });

  test('reports if statements with file/line/reason', () async {
    final errors = await checkSource('''
void main() {
  if (true) {
    print('hi');
  }
}
''');
    expect(errors, hasLength(1));
    expect(errors.single.line, 2);
    expect(errors.single.reason, contains('IfStatement'));
    expect(errors.single.filePath, endsWith('entry.dart'));
  });

  test('reports non-int locals', () async {
    final errors = await checkSource('''
void main() {
  var name = 'hi';
  print(name);
}
''');
    expect(errors, isNotEmpty);
    expect(errors.first.reason, contains('int locals'));
  });

  group('annotation bindings', () {
    test('accepts @GoName calls on @GoType locals and top-level functions',
        () async {
      final errors = await checkBindingSource('''
import 'package:test_binding/test_binding.dart';

void main() {
  final widget = newWidget();
  var n = 2;
  widget.show(1, 2, 'hi');
  beep(n);
}
''');
      expect(errors, isEmpty);
    });

    test('reports external functions without @GoName', () async {
      final errors = await checkBindingSource('''
import 'package:test_binding/test_binding.dart';

void main() {
  unnamed();
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.line, 4);
      expect(errors.single.reason, contains('no @GoName annotation'));
    });

    test('reports unsupported binding-call arguments', () async {
      final errors = await checkBindingSource('''
import 'package:test_binding/test_binding.dart';

void main() {
  final widget = newWidget();
  widget.show(1, 2, 'a' + 'b');
  beep(1 + 2);
}
''');
      expect(errors, hasLength(2));
      expect(errors[0].line, 5);
      expect(errors[0].reason, contains('argument must be an int literal'));
      expect(errors[1].line, 6);
    });

    test('reports binding methods called on non-local receivers', () async {
      final errors = await checkBindingSource('''
import 'package:test_binding/test_binding.dart';

void main() {
  newWidget().hide();
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('local variable'));
    });
  });

  test('reports missing main()', () async {
    final errors = await checkSource('''
int add(int a, int b) => a + b;
''');
    expect(
      errors.any((e) => e.reason.contains('no top-level void main()')),
      isTrue,
    );
  });
}
