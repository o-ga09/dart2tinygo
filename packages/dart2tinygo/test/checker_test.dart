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

    test('accepts while nested inside if (loop nesting, see #8)', () async {
      final errors = await checkSource('''
void main() {
  if (true) {
    while (true) {
      print('hi');
    }
  }
}
''');
      expect(errors, isEmpty);
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
  var sum = 1 & 2;
  if (sum > 0) { print('hi'); }
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.line, 2);
      expect(errors.single.reason, contains('"&"'));
    });
  });

  group('int arithmetic', () {
    test('accepts + - * ~/ % on matching int operands', () async {
      final errors = await checkSource('''
void main() {
  var a = -5;
  var b = a % 3;
  var c = a ~/ 3;
  var sum = a + b;
  var diff = a - b;
  var prod = a * b;
  print('\$sum \$diff \$prod \$c');
}
''');
      expect(errors, isEmpty);
    });

    test('accepts nested and parenthesized arithmetic', () async {
      final errors = await checkSource('''
void main() {
  var a = 1;
  var b = 2;
  var c = 3;
  var result = (a + b) * c - a % b;
  print('\$result');
}
''');
      expect(errors, isEmpty);
    });

    test('accepts arithmetic inside a comparison', () async {
      final errors = await checkSource('''
void main() {
  var a = 5;
  if (a % 2 == 0) {
    print('even');
  }
}
''');
      expect(errors, isEmpty);
    });

    test('accepts unary minus on an int local', () async {
      final errors = await checkSource('''
void main() {
  var a = 5;
  var b = -a;
  print('\$b');
}
''');
      expect(errors, isEmpty);
    });

    test('accepts += -= *= /= %= ~/= on int locals', () async {
      final errors = await checkSource('''
void main() {
  var i = 10;
  i += 1;
  i -= 1;
  i *= 2;
  i ~/= 2;
  i %= 3;
  print('\$i');
}
''');
      expect(errors, isEmpty);
    });

    test('reports arithmetic on mismatched types', () async {
      final errors = await checkSource('''
void main() {
  var a = 1;
  var x = 1.5;
  if (a + x > 0) {
    print('hi');
  }
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('int'));
    });

    test('reports arithmetic on String operands', () async {
      final errors = await checkSource('''
void main() {
  var s = 'a' + 'b';
  print(s);
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('int'));
    });

    test('reports unary minus on a non-int operand', () async {
      final errors = await checkSource('''
void main() {
  var x = 1.5;
  var y = -x;
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('int'));
    });

    test('reports %= and ~/= on a double local', () async {
      final errors = await checkSource('''
void main() {
  var x = 1.5;
  x %= 0.5;
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('int'));
    });
  });

  group('while loops', () {
    test('accepts a general bool condition', () async {
      final errors = await checkSource('''
void main() {
  var count = 0;
  while (count < 10) {
    count++;
  }
}
''');
      expect(errors, isEmpty);
    });

    test('accepts nested while loops', () async {
      final errors = await checkSource('''
void main() {
  var i = 0;
  while (i < 3) {
    var j = 0;
    while (j < 3) {
      j++;
    }
    i++;
  }
}
''');
      expect(errors, isEmpty);
    });

    test('reports a non-bool condition', () async {
      final errors = await checkSource('''
void main() {
  var count = 0;
  while (count) {
    count++;
  }
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('bool'));
    });
  });

  group('for loops', () {
    test('accepts a C-style for loop with a += updater', () async {
      final errors = await checkSource('''
void main() {
  for (var y = 0; y < 240; y += 20) {
    print('\$y');
  }
}
''');
      expect(errors, isEmpty);
    });

    test('accepts a C-style for loop with a ++ updater, nested in while',
        () async {
      final errors = await checkSource('''
void main() {
  while (true) {
    for (var i = 0; i < 10; i++) {
      print('\$i');
    }
  }
}
''');
      expect(errors, isEmpty);
    });

    test('reports a for loop without a condition', () async {
      final errors = await checkSource('''
void main() {
  for (var i = 0;; i++) {
    print('\$i');
  }
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('condition'));
    });

    test('reports a for loop whose initializer is not a declaration', () async {
      final errors = await checkSource('''
void main() {
  var i = 0;
  for (i = 0; i < 10; i++) {
    print('\$i');
  }
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('declare'));
    });

    test('reports a for loop with more than one declared variable', () async {
      final errors = await checkSource('''
void main() {
  for (var i = 0, j = 10; i < j; i++) {
    print('\$i');
  }
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('exactly one variable'));
    });

    test('reports a for loop with more than one updater', () async {
      final errors = await checkSource('''
void main() {
  var j = 10;
  for (var i = 0; i < j; i++, j--) {
    print('\$i');
  }
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('exactly one updater'));
    });

    test('reports a for-in loop', () async {
      final errors = await checkSource('''
void main() {
  for (var x in [1, 2, 3]) {
    print('\$x');
  }
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('for-in'));
    });

    test('reports a for-loop body without a block', () async {
      final errors = await checkSource('''
void main() {
  for (var i = 0; i < 10; i++) print('\$i');
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('block'));
    });
  });

  group('break and continue', () {
    test('accepts break inside a while loop', () async {
      final errors = await checkSource('''
void main() {
  while (true) {
    break;
  }
}
''');
      expect(errors, isEmpty);
    });

    test('accepts continue inside a for loop', () async {
      final errors = await checkSource('''
void main() {
  for (var i = 0; i < 10; i++) {
    continue;
  }
}
''');
      expect(errors, isEmpty);
    });

    test('accepts break/continue inside if nested in a loop', () async {
      final errors = await checkSource('''
void main() {
  var i = 0;
  while (i < 10) {
    if (i == 5) {
      break;
    } else {
      continue;
    }
  }
}
''');
      expect(errors, isEmpty);
    });

    test('reports break outside a loop', () async {
      final errors = await checkSource('''
void main() {
  break;
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('outside'));
    });

    test('reports continue outside a loop, even inside if', () async {
      final errors = await checkSource('''
void main() {
  if (true) {
    continue;
  }
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('outside'));
    });
  });

  group('compound assignment', () {
    test('accepts += -= *= /= on matching int/double locals', () async {
      final errors = await checkSource('''
void main() {
  var i = 0;
  i += 1;
  i -= 1;
  i *= 2;
  i /= 2;
  var x = 1.0;
  x += 0.5;
}
''');
      expect(errors, isEmpty);
    });

    test('reports a compound assignment with a mismatched rhs type', () async {
      final errors = await checkSource('''
void main() {
  var i = 0;
  i += 1.5;
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('int'));
    });

    test('reports a compound assignment on a bool local', () async {
      final errors = await checkSource('''
void main() {
  var ready = true;
  ready += true;
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('int/double'));
    });

    test('reports an unsupported assignment operator', () async {
      final errors = await checkSource('''
void main() {
  var i = 0;
  i &= 2;
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('"&="'));
    });
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
  beep(1 & 2);
}
''');
      expect(errors, hasLength(2));
      expect(errors[0].line, 5);
      expect(errors[0].reason, contains('"+"'));
      expect(errors[1].line, 6);
      expect(errors[1].reason, contains('"&"'));
    });

    test('accepts int arithmetic as a binding-call argument', () async {
      final errors = await checkBindingSource('''
import 'package:test_binding/test_binding.dart';

void main() {
  beep(1 + 2 * 3);
}
''');
      expect(errors, isEmpty);
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
