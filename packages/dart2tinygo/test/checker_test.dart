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

  group('if statements', () {
    test('accepts if / else if / else with a bool literal condition', () async {
      final errors = await checkSource('''
void main() {
  if (true) {
    print('hi');
  } else if (false) {
    print('bye');
  } else {
    print('neither');
  }
}
''');
      expect(errors, isEmpty);
    });

    test('accepts a bool local as the condition, with no else', () async {
      final errors = await checkSource('''
void main() {
  var ready = true;
  if (ready) {
    print('ready');
  }
}
''');
      expect(errors, isEmpty);
    });

    test('accepts if nested inside while, and nested if/else', () async {
      final errors = await checkSource('''
void main() {
  var count = 0;
  while (true) {
    if (count > 0) {
      if (count > 10) {
        print('big');
      } else {
        print('small');
      }
    }
    count++;
  }
}
''');
      expect(errors, isEmpty);
    });

    test('reports a non-bool condition with file/line/reason', () async {
      final errors = await checkSource('''
void main() {
  var count = 0;
  if (count) {
    print('hi');
  }
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.line, 3);
      expect(errors.single.reason, contains('bool'));
      expect(errors.single.filePath, endsWith('entry.dart'));
    });

    test('reports an if branch without a block', () async {
      final errors = await checkSource('''
void main() {
  if (true) print('hi');
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('block'));
    });

    test('reports an else branch without a block', () async {
      final errors = await checkSource('''
void main() {
  if (true) {
    print('hi');
  } else print('bye');
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('block'));
    });

    test('reports while nested inside if as out of scope', () async {
      final errors = await checkSource('''
void main() {
  if (true) {
    while (true) {
      print('hi');
    }
  }
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('WhileStatement'));
    });
  });

  group('comparison and logical operators', () {
    test('accepts ==, !=, <, <=, >, >= on matching int/double operands',
        () async {
      final errors = await checkSource('''
void main() {
  var a = 1;
  var b = 2;
  var x = 1.5;
  var y = 2.5;
  if (a == b) { print('1'); }
  if (a != b) { print('2'); }
  if (a < b) { print('3'); }
  if (a <= b) { print('4'); }
  if (a > b) { print('5'); }
  if (a >= b) { print('6'); }
  if (x < y) { print('7'); }
  if (true == false) { print('8'); }
  if ('a' == 'b') { print('9'); }
}
''');
      expect(errors, isEmpty);
    });

    test('accepts && / || / ! combined and parenthesized', () async {
      final errors = await checkSource('''
void main() {
  var a = true;
  var b = false;
  if (a && b) { print('1'); }
  if (a || b) { print('2'); }
  if (!a) { print('3'); }
  if (!(a && b) || (b && !a)) { print('4'); }
}
''');
      expect(errors, isEmpty);
    });

    test('reports comparison of mismatched types', () async {
      final errors = await checkSource('''
void main() {
  var a = 1;
  var x = 1.5;
  if (a == x) { print('hi'); }
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('same type'));
    });

    test('reports ordering comparisons on bool/String operands', () async {
      final errors = await checkSource('''
void main() {
  if ('a' < 'b') { print('hi'); }
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('int and double'));
    });

    test('reports && / || with a non-bool operand', () async {
      final errors = await checkSource('''
void main() {
  var a = 1;
  var b = true;
  if (a && b) { print('hi'); }
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('bool'));
    });

    test('reports ! on a non-bool operand', () async {
      final errors = await checkSource('''
void main() {
  var a = 1;
  if (!a) { print('hi'); }
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('bool'));
    });

    test('reports unsupported binary operators', () async {
      final errors = await checkSource('''
void main() {
  var sum = 1 + 2;
  if (sum > 0) { print('hi'); }
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.line, 2);
      expect(errors.single.reason, contains('"+"'));
    });
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
    expect(errors.single.reason, contains('"+"'));
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
      expect(errors[0].reason, contains('"+"'));
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
