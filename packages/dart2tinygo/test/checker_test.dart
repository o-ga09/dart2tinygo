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

  test('accepts int/double/bool/String literal locals', () async {
    final errors = await checkSource('''
void main() {
  var count = 0;
  var ratio = 0.5;
  double whole = 2;
  final ready = true;
  const name = 'hi';
  print('\$count \$ready \$name');
  print(name);
}
''');
    expect(errors, isEmpty);
  });

  test('reports locals of unsupported types', () async {
    final errors = await checkSource('''
void main() {
  var d = const Duration(seconds: 1);
  var xs = [1, 2];
}
''');
    expect(errors, hasLength(2));
    expect(errors[0].line, 2);
    expect(errors[0].reason, contains('"Duration"'));
    expect(errors[0].reason, contains('int, double, bool, String'));
    expect(errors[1].line, 3);
  });

  test('reports unsupported local initializers', () async {
    final errors = await checkSource('''
void main() {
  var sum = 1 + 2;
}
''');
    expect(errors, hasLength(1));
    expect(errors.single.line, 2);
    expect(errors.single.reason, contains('BinaryExpression'));
  });

  test('reports double interpolation as not supported yet', () async {
    final errors = await checkSource('''
void main() {
  var ratio = 0.5;
  print('r=\$ratio');
}
''');
    expect(errors, hasLength(1));
    expect(errors.single.line, 3);
    expect(errors.single.reason, contains('double'));
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

    test('accepts non-void results, typed arguments, and Go constants',
        () async {
      final errors = await checkBindingSource('''
import 'package:test_binding/test_binding.dart';

void main() {
  final widget = newWidget();
  final level = readLevel();
  final ready = isReady();
  final volts = voltage();
  final name = label();
  final color = rgb(1, 2, 3);
  final button = Button.a;
  widget.fill(color);
  widget.fill(red);
  widget.fill(rgb(4, 5, 6));
  widget.configure(ready, volts, name);
  widget.configure(false, 1.5, 'x');
  final pressed = widget.press(Button.b);
  print('\$level \$ready \$name \$pressed \${widget.level()}');
  print(label());
  beep(readLevel());
  beep(widget.level());
}
''');
      expect(errors, isEmpty);
    });

    test('reports constant getters without @GoName', () async {
      final errors = await checkBindingSource('''
import 'package:test_binding/test_binding.dart';

void main() {
  final widget = newWidget();
  widget.fill(unnamedColor);
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.line, 5);
      expect(errors.single.reason, contains('no @GoName annotation'));
    });

    test('reports binding results of unsupported types in interpolation',
        () async {
      final errors = await checkBindingSource('''
import 'package:test_binding/test_binding.dart';

void main() {
  print('v=\${voltage()}');
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('double'));
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
      expect(errors[0].reason, contains('BinaryExpression'));
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
