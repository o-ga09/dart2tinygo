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

  test('accepts the v0.0.1 minimal subset', () async {
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

    // `var y = -s;` for a String `s` doesn't reach this check at all: Dart's
    // own analyzer has no `String.operator-`, so `y`'s inferred type is
    // already `InvalidType` and the surrounding local-variable check
    // rejects it first. A binding-call argument isn't gated that way, so
    // it reaches this code path directly.
    test('reports unary minus on a non-numeric operand', () async {
      final errors = await checkBindingSource('''
import 'package:test_binding/test_binding.dart';

void main() {
  final widget = newWidget();
  var s = 'hi';
  widget.fill(-s);
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('int/double'));
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

  group('double arithmetic and int/double conversion', () {
    test('accepts + - * / on matching double operands', () async {
      final errors = await checkSource('''
void main() {
  var a = 1.5;
  var b = 2.5;
  var sum = a + b;
  var diff = a - b;
  var prod = a * b;
  var quot = a / b;
  print('\$sum \$diff \$prod \$quot');
}
''');
      expect(errors, isEmpty);
    });

    test('accepts nested and parenthesized double arithmetic', () async {
      final errors = await checkSource('''
void main() {
  var a = 1.0;
  var b = 2.0;
  var c = 3.0;
  var result = (a + b) * c / a;
  print('\$result');
}
''');
      expect(errors, isEmpty);
    });

    test('accepts double arithmetic inside a comparison', () async {
      final errors = await checkSource('''
void main() {
  var a = 1.0;
  var b = 2.0;
  if (a / b > 0.25) {
    print('big enough');
  }
}
''');
      expect(errors, isEmpty);
    });

    test('accepts unary minus on a double local', () async {
      final errors = await checkSource('''
void main() {
  var a = 1.5;
  var b = -a;
  print('\$b');
}
''');
      expect(errors, isEmpty);
    });

    test('reports / on int operands', () async {
      final errors = await checkSource('''
void main() {
  var a = 1;
  var b = 2;
  var q = a / b;
  print('\$q');
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('double'));
    });

    test('reports + - * on mixed int/double operands', () async {
      final errors = await checkSource('''
void main() {
  var a = 1;
  var b = 2.0;
  var sum = a + b;
  print('\$sum');
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('int'));
      expect(errors.single.reason, contains('double'));
    });

    test('accepts toDouble() on an int expression', () async {
      final errors = await checkSource('''
void main() {
  var raw = 5;
  var scaled = raw.toDouble() / 2.0;
  print('\$scaled');
}
''');
      expect(errors, isEmpty);
    });

    test('accepts toInt() and round() on a double expression', () async {
      final errors = await checkSource('''
void main() {
  var x = 3.7;
  var truncated = x.toInt();
  var rounded = x.round();
  print('\$truncated \$rounded');
}
''');
      expect(errors, isEmpty);
    });

    test('accepts a conversion result used directly, without a local',
        () async {
      final errors = await checkSource('''
void main() {
  var raw = 5;
  print('\${raw.toDouble()}');
}
''');
      expect(errors, isEmpty);
    });

    test('reports toDouble() on a double receiver', () async {
      final errors = await checkSource('''
void main() {
  var x = 1.5;
  var y = x.toDouble();
  print('\$y');
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('int receiver'));
    });

    test('reports toInt() on an int receiver', () async {
      final errors = await checkSource('''
void main() {
  var x = 1;
  var y = x.toInt();
  print('\$y');
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('double receiver'));
    });

    test('reports round() on an int receiver', () async {
      final errors = await checkSource('''
void main() {
  var x = 1;
  var y = x.round();
  print('\$y');
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('double receiver'));
    });

    test('reports arguments passed to toDouble()', () async {
      final errors = await checkSource('''
void main() {
  var x = 1;
  var y = x.toDouble(2);
  print('\$y');
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('no arguments'));
    });

    test('accepts double string interpolation', () async {
      final errors = await checkSource('''
void main() {
  var x = 1.5;
  print('x=\$x');
}
''');
      expect(errors, isEmpty);
    });
  });

  group('top-level functions', () {
    test('accepts a function with an expression body', () async {
      final errors = await checkSource('''
int square(int x) => x * x;

void main() {
  print('\${square(3)}');
}
''');
      expect(errors, isEmpty);
    });

    test('accepts a function with a block body and return', () async {
      final errors = await checkSource('''
int add(int a, int b) {
  var sum = a + b;
  return sum;
}

void main() {
  print('\${add(1, 2)}');
}
''');
      expect(errors, isEmpty);
    });

    test('accepts a void function with an expression body', () async {
      final errors = await checkSource('''
void log(String s) => print(s);

void main() {
  log('hi');
}
''');
      expect(errors, isEmpty);
    });

    test('accepts a void function with a bare return', () async {
      final errors = await checkSource('''
void logIfPositive(int x) {
  if (x <= 0) {
    return;
  }
  print('\$x');
}

void main() {
  logIfPositive(1);
}
''');
      expect(errors, isEmpty);
    });

    test('accepts multiple parameters of different supported types', () async {
      final errors = await checkSource('''
String describe(int n, double ratio, bool ready, String name) {
  return name;
}

void main() {
  print(describe(1, 1.5, true, 'x'));
}
''');
      expect(errors, isEmpty);
    });

    test('accepts a @GoType parameter and return type', () async {
      final errors = await checkBindingSource('''
import 'package:test_binding/test_binding.dart';

void pressTwice(Widget w, Button b) {
  w.press(b);
  w.press(b);
}

Button firstButton() => Button.a;

void main() {
  final widget = newWidget();
  pressTwice(widget, firstButton());
}
''');
      expect(errors, isEmpty);
    });

    test('accepts recursion', () async {
      final errors = await checkSource('''
int fib(int n) {
  if (n < 2) {
    return n;
  }
  return fib(n - 1) + fib(n - 2);
}

void main() {
  print('\${fib(5)}');
}
''');
      expect(errors, isEmpty);
    });

    test('accepts a call to a function declared later in the file', () async {
      final errors = await checkSource('''
void main() {
  print('\${later(1)}');
}

int later(int x) => x + 1;
''');
      expect(errors, isEmpty);
    });

    test('accepts a function call as a statement, discarding its result',
        () async {
      final errors = await checkSource('''
int next(int x) => x + 1;

void main() {
  next(1);
}
''');
      expect(errors, isEmpty);
    });

    test('accepts a List<int> parameter and return type', () async {
      final errors = await checkSource('''
List<int> withFirst(List<int> data, int first) {
  data[0] = first;
  return data;
}

void main() {
  var data = <int>[0, 0];
  var updated = withFirst(data, 9);
  print('\${updated.length}');
}
''');
      expect(errors, isEmpty);
    });

    test('reports a named parameter', () async {
      final errors = await checkSource('''
int f({required int x}) => x;

void main() {
  print('\${f(x: 1)}');
}
''');
      expect(errors, isNotEmpty);
      expect(errors.first.reason, contains('positional'));
    });

    test('reports an optional positional parameter', () async {
      final errors = await checkSource('''
int f([int x = 0]) => x;

void main() {
  print('\${f()}');
}
''');
      expect(errors, isNotEmpty);
      expect(errors.first.reason, contains('positional'));
    });

    test('reports an unsupported parameter type', () async {
      final errors = await checkSource('''
void f(Object x) {}

void main() {
  f(1);
}
''');
      expect(errors, isNotEmpty);
      expect(errors.first.reason, contains('Object'));
    });

    test('reports an unsupported return type', () async {
      final errors = await checkSource('''
Object f() => 1;

void main() {
  f();
}
''');
      expect(errors, isNotEmpty);
      expect(errors.first.reason, contains('Object'));
    });
  });

  group('List<int>', () {
    test('accepts a List<int> local with an explicit type argument', () async {
      final errors = await checkSource('''
void main() {
  var data = <int>[1, 2, 3];
  print('\${data.length}');
}
''');
      expect(errors, isEmpty);
    });

    test('accepts a List<int> local with an inferred literal', () async {
      final errors = await checkSource('''
void main() {
  var data = [1, 2, 3];
  print('\${data.length}');
}
''');
      expect(errors, isEmpty);
    });

    test('accepts an empty List<int> with a declared type', () async {
      final errors = await checkSource('''
void main() {
  List<int> data = [];
  print('\${data.length}');
}
''');
      expect(errors, isEmpty);
    });

    test('accepts index read into an int local', () async {
      final errors = await checkSource('''
void main() {
  var data = <int>[1, 2, 3];
  var x = data[0];
  print('\$x');
}
''');
      expect(errors, isEmpty);
    });

    test('accepts index write', () async {
      final errors = await checkSource('''
void main() {
  var data = <int>[1, 2, 3];
  data[0] = 42;
  var i = 1;
  data[i] = data[0];
}
''');
      expect(errors, isEmpty);
    });

    test('accepts add() as a statement', () async {
      final errors = await checkSource('''
void main() {
  var data = <int>[1, 2, 3];
  data.add(4);
  var n = 5;
  data.add(n);
}
''');
      expect(errors, isEmpty);
    });

    test('accepts a List<int> local as a binding-call argument', () async {
      final errors = await checkBindingSource('''
import 'package:test_binding/test_binding.dart';

void main() {
  var data = <int>[1, 2, 3];
  beep(data.length);
}
''');
      expect(errors, isEmpty);
    });

    test('reports a list literal of non-int elements', () async {
      final errors = await checkSource('''
void main() {
  var data = <double>[1.0, 2.0];
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('List<int>'));
    });

    test('reports index read/write on a non-local receiver', () async {
      final errors = await checkSource('''
void main() {
  var x = <int>[1, 2, 3][0];
  print('\$x');
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('local variable'));
    });

    test('reports add() with the wrong number of arguments', () async {
      final errors = await checkSource('''
void main() {
  var data = <int>[1, 2, 3];
  data.add(1, 2);
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('one argument'));
    });

    test('reports List<int> equality as unsupported', () async {
      final errors = await checkSource('''
void main() {
  var a = <int>[1];
  var b = <int>[1];
  if (a == b) {
    print('same');
  }
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('same type'));
    });
  });

  group('String operations', () {
    test('accepts .length on a String local and literal', () async {
      final errors = await checkSource('''
void main() {
  var s = 'hello';
  var n1 = s.length;
  var n2 = 'hi'.length;
  print('\$n1 \$n2');
}
''');
      expect(errors, isEmpty);
    });

    test('accepts .codeUnits on a String local and literal', () async {
      final errors = await checkSource('''
void main() {
  var s = 'hello';
  var a = s.codeUnits;
  var b = 'hi'.codeUnits;
  print('\${a.length} \${b.length}');
}
''');
      expect(errors, isEmpty);
    });

    test('accepts String.fromCharCodes()', () async {
      final errors = await checkSource('''
void main() {
  var data = <int>[104, 105];
  var s = String.fromCharCodes(data);
  print(s);
}
''');
      expect(errors, isEmpty);
    });

    test('accepts substring() with one or two arguments', () async {
      final errors = await checkSource('''
void main() {
  var s = 'hello world';
  var a = s.substring(6);
  var b = s.substring(0, 5);
  print('\$a \$b');
}
''');
      expect(errors, isEmpty);
    });

    test('accepts String + String', () async {
      final errors = await checkSource('''
void main() {
  var a = 'hello';
  var b = 'world';
  var c = a + b;
  print(c);
}
''');
      expect(errors, isEmpty);
    });

    test(
        'accepts codeUnits round-tripped through fromCharCodes as a '
        'binding-call argument', () async {
      final errors = await checkBindingSource('''
import 'package:test_binding/test_binding.dart';

void main() {
  final widget = newWidget();
  widget.show(1, 2, String.fromCharCodes('hi'.codeUnits));
}
''');
      expect(errors, isEmpty);
    });

    test('reports String - and * as unsupported', () async {
      final errors = await checkBindingSource('''
import 'package:test_binding/test_binding.dart';

void main() {
  var a = 'hello';
  var b = 'world';
  beep(a - b);
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('String'));
    });

    test('reports substring() with the wrong number of arguments', () async {
      final errors = await checkSource('''
void main() {
  var s = 'hello';
  var a = s.substring();
  print(a);
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('argument'));
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
    test('accepts += -= *= on matching int/double locals', () async {
      final errors = await checkSource('''
void main() {
  var i = 0;
  i += 1;
  i -= 1;
  i *= 2;
  var x = 1.0;
  x += 0.5;
  x -= 0.5;
  x *= 2.0;
  x /= 2.0;
}
''');
      expect(errors, isEmpty);
    });

    // Dart's `/` (and therefore `/=`) always returns double, even for two
    // ints — `i /= 2;` on an int `i` is a genuine Dart compile error
    // ("A value of type 'double' can't be assigned to a variable of type
    // 'int'"), not merely unsupported syntax. Verified with `dart analyze`
    // against this exact snippet.
    test('reports /= on an int target', () async {
      final errors = await checkSource('''
void main() {
  var i = 0;
  i /= 2;
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('double'));
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

  group('switch statements', () {
    test('accepts switch on int with grouped and default cases', () async {
      final errors = await checkSource('''
void main() {
  var mode = 2;
  switch (mode) {
    case 0:
      print('off');
    case 1:
    case 2:
      print('on');
    default:
      print('?');
  }
}
''');
      expect(errors, isEmpty);
    });

    test('accepts switch on String', () async {
      final errors = await checkSource('''
void main() {
  var name = 'b';
  switch (name) {
    case 'a':
      print('first');
    case 'b':
      print('second');
    default:
      print('other');
  }
}
''');
      expect(errors, isEmpty);
    });

    test('accepts switch on bool with no default', () async {
      final errors = await checkSource('''
void main() {
  var flag = true;
  switch (flag) {
    case true:
      print('yes');
    case false:
      print('no');
  }
}
''');
      expect(errors, isEmpty);
    });

    test('accepts switch nested inside while, with break/continue outside',
        () async {
      final errors = await checkSource('''
void main() {
  var count = 0;
  while (count < 3) {
    switch (count) {
      case 0:
        print('zero');
      default:
        print('other');
    }
    count++;
  }
}
''');
      expect(errors, isEmpty);
    });

    test('reports a switch expression with an unsupported type', () async {
      final errors = await checkSource('''
void main() {
  var mode = 1.5;
  switch (mode) {
    case 1.5:
      print('x');
  }
}
''');
      expect(errors, isNotEmpty);
      expect(errors.first.reason, contains('int/String/bool'));
    });

    test('reports a case value whose type does not match the switch expression',
        () async {
      final errors = await checkSource('''
void main() {
  var mode = 1;
  switch (mode) {
    case 'a':
      print('x');
  }
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('does not match'));
    });

    test('reports a case pattern that is not a constant value', () async {
      final errors = await checkSource('''
void main() {
  var mode = 1;
  switch (mode) {
    case var x:
      print('hi');
  }
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('not supported'));
    });

    test('reports a "case ... when ..." guard', () async {
      final errors = await checkSource('''
void main() {
  var mode = 1;
  switch (mode) {
    case 1 when mode > 0:
      print('x');
  }
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('when'));
    });

    test('reports a labeled switch case', () async {
      final errors = await checkSource('''
void main() {
  var mode = 1;
  switch (mode) {
    outer:
    case 1:
      print('x');
  }
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('labeled'));
    });
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

    test('accepts a double binding result in interpolation', () async {
      final errors = await checkBindingSource('''
import 'package:test_binding/test_binding.dart';

void main() {
  print('v=\${voltage()}');
}
''');
      expect(errors, isEmpty);
    });

    test('reports binding results of unsupported types in interpolation',
        () async {
      final errors = await checkBindingSource('''
import 'package:test_binding/test_binding.dart';

void main() {
  print('c=\${rgb(1, 2, 3)}');
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('Color'));
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
  widget.show(1, 2, 'a' - 'b');
  beep(1 & 2);
}
''');
      expect(errors, hasLength(2));
      expect(errors[0].line, 5);
      expect(errors[0].reason, contains('"-"'));
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

    test(
        'accepts a @GoType class construction with @GoName on the '
        'constructor', () async {
      final errors = await checkBindingSource('''
import 'package:test_binding/test_binding.dart';

void main() {
  final gpio = Gpio(3);
  beep(gpio.value());
  beep(Gpio(1 + 2).value());
}
''');
      expect(errors, isEmpty);
    });

    test('reports a @GoType class constructor without @GoName', () async {
      final errors = await checkBindingSource('''
import 'package:test_binding/test_binding.dart';

void main() {
  final gpio = BadGpio(3);
  beep(1);
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.line, 4);
      expect(errors.single.reason, contains('no @GoName annotation'));
    });
  });

  group('cascade and method chaining', () {
    test('accepts a binding method called on a call-result receiver', () async {
      final errors = await checkBindingSource('''
import 'package:test_binding/test_binding.dart';

void main() {
  newWidget().hide();
}
''');
      expect(errors, isEmpty);
    });

    test('accepts multi-level chaining and a chained call as a value',
        () async {
      final errors = await checkBindingSource('''
import 'package:test_binding/test_binding.dart';

void main() {
  var n = newWidget().level();
  beep(n);
}
''');
      expect(errors, isEmpty);
    });

    test('accepts a cascade as a statement', () async {
      final errors = await checkBindingSource('''
import 'package:test_binding/test_binding.dart';

void main() {
  newWidget()
    ..show(0, 0, 'a')
    ..hide();
}
''');
      expect(errors, isEmpty);
    });

    test('accepts a cascade as a local initializer', () async {
      final errors = await checkBindingSource('''
import 'package:test_binding/test_binding.dart';

void main() {
  final widget = newWidget()
    ..show(0, 0, 'a')
    ..hide();
  beep(widget.level());
}
''');
      expect(errors, isEmpty);
    });

    test('reports a cascade on a non-@GoType target', () async {
      final errors = await checkBindingSource('''
import 'package:test_binding/test_binding.dart';

void main() {
  readLevel()..toString();
}
''');
      expect(errors, isNotEmpty);
      expect(errors.first.reason, contains('@GoType'));
    });

    test('reports a cascade section that is not a binding method call',
        () async {
      final errors = await checkBindingSource('''
import 'package:test_binding/test_binding.dart';

void main() {
  newWidget()..level;
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('cascade section'));
    });

    test('reports a cascade method without @GoName', () async {
      final errors = await checkBindingSource('''
import 'package:test_binding/test_binding.dart';

void main() {
  newWidget()..toString();
}
''');
      expect(errors, hasLength(1));
    });
  });

  group('enum', () {
    test('accepts a user enum: declaration, .name, .index, comparison',
        () async {
      final errors = await checkSource('''
enum Mode { off, on }

void main() {
  var m = Mode.on;
  print(m.name);
  print('\${m.index}');
  if (m == Mode.on) {
    print('on');
  }
}
''');
      expect(errors, isEmpty);
    });

    test('accepts switch on a user enum', () async {
      final errors = await checkSource('''
enum Mode { off, on }

void main() {
  var m = Mode.on;
  switch (m) {
    case Mode.off:
      print('off');
    case Mode.on:
      print('on');
  }
}
''');
      expect(errors, isEmpty);
    });

    test('accepts a @GoType binding enum constant as a binding-call argument',
        () async {
      final errors = await checkBindingSource('''
import 'package:test_binding/test_binding.dart';

void main() {
  high(Pin.led);
}
''');
      expect(errors, isEmpty);
    });

    test('reports a binding enum constant without @GoName', () async {
      final errors = await checkBindingSource('''
import 'package:test_binding/test_binding.dart';

void main() {
  var p = BadPin.unnamed;
}
''');
      expect(errors, isNotEmpty);
      expect(errors.first.reason, contains('no @GoName annotation'));
    });

    test('reports an enum with type parameters', () async {
      final errors = await checkSource('''
enum Mode<T> { off, on }

void main() {}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('type parameters'));
    });

    test('reports an enum with extra fields/methods', () async {
      final errors = await checkSource('''
enum Mode {
  off, on;

  String label() => name;
}

void main() {}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('fields or methods'));
    });

    test('reports a switch expression of unsupported (non-matching) enum type',
        () async {
      final errors = await checkSource('''
enum Mode { off, on }
enum Level { low, high }

void main() {
  var m = Mode.on;
  switch (m) {
    case Level.low:
      print('x');
  }
}
''');
      expect(errors, hasLength(1));
      expect(errors.single.reason, contains('does not match'));
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

  group('class (#32)', () {
    test(
        'accepts fields, a this.x constructor, methods, field access, and '
        'instance method calls', () async {
      final errors = await checkSource('''
class Counter {
  int value;

  Counter(this.value);

  void inc() {
    value++;
  }

  int addTo(int value) => this.value + value;
}

void main() {
  final c = Counter(0);
  c.inc();
  print('\${c.value}');
  print('\${c.addTo(3)}');
  c.value = 10;
  c.value += 5;
  var same = c == c;
}
''');
      expect(errors, isEmpty);
    });

    test('accepts a constructor body that reassigns a this.x field', () async {
      final errors = await checkSource('''
class Rect {
  int width;
  int height;

  Rect(this.width, this.height) {
    if (width < 0) {
      width = 0;
    }
  }

  int area() => width * height;

  void grow() {
    width++;
    bumpHeight();
  }

  void bumpHeight() {
    height += 1;
  }
}

void main() {
  final r = Rect(3, 4);
  print('\${r.area()}');
  r.grow();
}
''');
      expect(errors, isEmpty);
    });

    test('reports extends/implements/with', () async {
      final errors = await checkSource('''
class Base {
  int x;
  Base(this.x);
}

class Derived extends Base {
  Derived(super.x);
}

void main() {}
''');
      expect(errors, isNotEmpty);
      expect(
        errors.any((e) => e.reason.contains('no inheritance')),
        isTrue,
      );
    });

    test('reports an abstract class', () async {
      final errors = await checkSource('''
abstract class Shape {
  int sides;
  Shape(this.sides);
}

void main() {}
''');
      expect(errors, isNotEmpty);
      expect(errors.any((e) => e.reason.contains('class modifier')), isTrue);
    });

    test('reports a class with type parameters', () async {
      final errors = await checkSource('''
class Box<T> {
  int x;
  Box(this.x);
}

void main() {}
''');
      expect(errors, isNotEmpty);
      expect(
        errors.any((e) => e.reason.contains('type parameters')),
        isTrue,
      );
    });

    test('reports a static field', () async {
      final errors = await checkSource('''
class Counter {
  static int total = 0;
  int value;
  Counter(this.value);
}

void main() {}
''');
      expect(errors, isNotEmpty);
      expect(errors.any((e) => e.reason.contains('static')), isTrue);
    });

    test('reports a static method', () async {
      final errors = await checkSource('''
class Counter {
  int value;
  Counter(this.value);
  static Counter zero() => Counter(0);
}

void main() {}
''');
      expect(errors, isNotEmpty);
      expect(errors.any((e) => e.reason.contains('static')), isTrue);
    });

    test('reports a getter and a setter', () async {
      final errors = await checkSource('''
class Counter {
  int value;
  Counter(this.value);
  int get doubled => value * 2;
  set doubled(int v) {
    value = v ~/ 2;
  }
}

void main() {}
''');
      expect(errors, isNotEmpty);
      expect(
        errors.any((e) => e.reason.contains('getter/setter')),
        isTrue,
      );
    });

    test('reports an operator== override', () async {
      final errors = await checkSource('''
class Counter {
  int value;
  Counter(this.value);
  @override
  bool operator ==(Object other) =>
      other is Counter && other.value == value;
}

void main() {}
''');
      expect(errors, isNotEmpty);
      expect(errors.any((e) => e.reason.contains('operator')), isTrue);
    });

    test('reports a nullable field type', () async {
      final errors = await checkSource('''
class Counter {
  int? value;
  Counter(this.value);
}

void main() {}
''');
      expect(errors, isNotEmpty);
      expect(errors.any((e) => e.reason.contains('nullable')), isTrue);
    });

    test('reports throw as unsupported', () async {
      final errors = await checkSource('''
class Counter {
  int value;
  Counter(this.value);
  void checked() {
    if (value < 0) {
      throw Exception('negative');
    }
  }
}

void main() {}
''');
      expect(errors, isNotEmpty);
    });

    test('reports zero constructors', () async {
      final errors = await checkSource('''
class Counter {
  int value = 0;
}

void main() {}
''');
      expect(errors, isNotEmpty);
      expect(
        errors.any((e) => e.reason.contains('exactly one constructor')),
        isTrue,
      );
    });

    test('reports more than one constructor', () async {
      final errors = await checkSource('''
class Counter {
  int value;
  Counter(this.value);
  Counter.zero() : value = 0;
}

void main() {}
''');
      expect(errors, isNotEmpty);
      expect(
        errors.any((e) => e.reason.contains('exactly one constructor')),
        isTrue,
      );
    });

    test('reports a named constructor', () async {
      final errors = await checkSource('''
class Counter {
  int value;
  Counter.named(this.value);
}

void main() {}
''');
      expect(errors, isNotEmpty);
      expect(errors.any((e) => e.reason.contains('unnamed')), isTrue);
    });

    test('reports a const constructor and an initializer list', () async {
      final errors = await checkSource('''
class Point {
  final int x;
  final int y;
  const Point(this.x) : y = 0;
}

void main() {}
''');
      expect(errors, isNotEmpty);
      expect(
        errors.any((e) => e.reason.contains('const/factory/external')),
        isTrue,
      );
      expect(
        errors.any((e) => e.reason.contains('initializer list')),
        isTrue,
      );
    });

    test('reports a field with a declaration-site initializer', () async {
      final errors = await checkSource('''
class Counter {
  int value = 0;
  Counter();
}

void main() {}
''');
      expect(errors, isNotEmpty);
      expect(
        errors.any((e) => e.reason.contains('must not have an initializer')),
        isTrue,
      );
    });
  });
}
