import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart2tinygo/src/frontend/bindings.dart';

/// A single instance of Dart syntax that is outside the currently supported
/// subset. Reported with file/line so it can be surfaced by `check`/`build`
/// the way `HANDOFF_dart2tinygo.md` §4.1/§4.2 describes.
class UnsupportedSyntaxError {
  UnsupportedSyntaxError({
    required this.filePath,
    required this.line,
    required this.column,
    required this.reason,
  });

  final String filePath;
  final int line;
  final int column;
  final String reason;

  @override
  String toString() => '$filePath:$line:$column: $reason';
}

/// v0.1 minimal scope only: a single `void main()` containing
/// `int`/`double`/`bool`/`String` locals, `while (true)`, `print(...)`,
/// `sleep(Duration(...))`, and calls into annotation bindings (`@GoImport` /
/// `@GoName` / `@GoType`, see `docs/writing_bindings.md`). Everything else
/// is reported here, up front, rather than discovered mid-conversion.
List<UnsupportedSyntaxError> checkEntryPoint(ResolvedUnitResult result) {
  final errors = <UnsupportedSyntaxError>[];
  final unit = result.unit;

  FunctionDeclaration? mainDecl;
  for (final declaration in unit.declarations) {
    if (declaration is FunctionDeclaration &&
        declaration.name.lexeme == 'main') {
      if (mainDecl != null) {
        errors.add(
            _error(result, declaration.offset, 'duplicate main() declaration'));
        continue;
      }
      mainDecl = declaration;
      continue;
    }
    errors.add(
      _error(
        result,
        declaration.offset,
        'top-level "${_declarationLabel(declaration)}" is not supported yet; '
        'v0.1 minimal scope only supports a single top-level void main()',
      ),
    );
  }

  if (mainDecl == null) {
    errors.add(_error(result, 0, 'no top-level void main() found'));
    return errors;
  }

  final params = mainDecl.functionExpression.parameters;
  if (params != null && params.parameters.isNotEmpty) {
    errors.add(
      _error(
        result,
        params.offset,
        'main() with parameters is not supported yet; use void main()',
      ),
    );
  }

  final body = mainDecl.functionExpression.body;
  if (body is! BlockFunctionBody) {
    errors.add(
        _error(result, body.offset, 'main() must have a block body: { ... }'));
    return errors;
  }

  for (final statement in body.block.statements) {
    errors.addAll(_checkStatement(result, statement, allowWhile: true));
  }

  return errors;
}

List<UnsupportedSyntaxError> _checkStatement(
  ResolvedUnitResult result,
  Statement statement, {
  required bool allowWhile,
}) {
  final errors = <UnsupportedSyntaxError>[];

  switch (statement) {
    case VariableDeclarationStatement():
      for (final variable in statement.variables.variables) {
        final initializer = variable.initializer;
        if (initializer == null) {
          errors.add(
            _error(
              result,
              variable.offset,
              'local variable "${variable.name.lexeme}" must have an initializer',
            ),
          );
          continue;
        }
        final type = variable.declaredFragment?.element.type;
        if (!_isSupportedType(type)) {
          errors.add(
            _error(
              result,
              variable.offset,
              'local variable "${variable.name.lexeme}" has type '
              '"${type?.getDisplayString() ?? '?'}", but only '
              '$_supportedTypesLabel locals are supported',
            ),
          );
          continue;
        }
        errors.addAll(_checkExpression(result, initializer));
      }

    case ExpressionStatement():
      errors.addAll(_checkExpressionStatement(result, statement));

    case WhileStatement() when allowWhile:
      final condition = statement.condition;
      if (condition is! BooleanLiteral || condition.value != true) {
        errors.add(
          _error(
            result,
            condition.offset,
            'only "while (true)" is supported in v0.1 minimal scope',
          ),
        );
      }
      final body = statement.body;
      if (body is! Block) {
        errors.add(
            _error(result, body.offset, 'while body must be a block: { ... }'));
      } else {
        for (final inner in body.statements) {
          // Nested loops are out of scope for the minimal transpile.
          errors.addAll(_checkStatement(result, inner, allowWhile: false));
        }
      }

    default:
      errors.add(
        _error(
          result,
          statement.offset,
          '"${_statementLabel(statement)}" is not supported in v0.1 minimal '
          'scope (only locals, while (true), print(...), sleep(...), and '
          'binding calls)',
        ),
      );
  }

  return errors;
}

List<UnsupportedSyntaxError> _checkExpressionStatement(
  ResolvedUnitResult result,
  ExpressionStatement statement,
) {
  final expression = statement.expression;

  if (expression is PostfixExpression &&
      (expression.operator.lexeme == '++' ||
          expression.operator.lexeme == '--')) {
    final type = expression.staticType;
    if (type == null || !type.isDartCoreInt) {
      return [
        _error(
          result,
          expression.offset,
          '"${expression.operator.lexeme}" is only supported on int locals',
        ),
      ];
    }
    return const [];
  }

  if (expression is MethodInvocation) {
    if (expression.target == null) {
      switch (expression.methodName.name) {
        case 'print':
          return _checkPrintCall(result, expression);
        case 'sleep':
          return _checkSleepCall(result, expression);
      }
    }
    if (_bindingOf(expression) != null ||
        _describeBindingProblem(expression) != null) {
      // A binding call as a statement; a non-void result is discarded.
      return _checkExpression(result, expression);
    }
  }

  return [
    _error(
      result,
      expression.offset,
      'expression "${_expressionLabel(expression)}" is not supported in '
      'v0.1 minimal scope (only x++/x--, print(...), sleep(...), and '
      'binding calls)',
    ),
  ];
}

/// The `@GoName` binding behind [call], or `null` if [call] is not a
/// (complete) binding call. A binding call is either a bare call to an
/// `external` top-level function, or a method call on a local whose type is
/// a `@GoType` class; in both cases the callee must be `external`, carry
/// `@GoName`, and come from a library with `@GoImport`.
GoBinding? _bindingOf(MethodInvocation call) {
  final callee = call.methodName.element;
  if (callee is! ExecutableElement) return null;
  final target = call.target;
  if (target == null) {
    if (callee is! TopLevelFunctionElement) return null;
  } else {
    if (callee is! MethodElement) return null;
    if (target is! SimpleIdentifier ||
        target.element is! LocalVariableElement ||
        !isGoType(target.staticType)) {
      return null;
    }
  }
  return goBindingOf(callee);
}

/// Explains why [reference] (a call or a constant reference) looks like a
/// binding but isn't one, so binding authors get a pointer at the missing
/// annotation rather than a generic "unsupported expression".
String? _describeBindingProblem(Expression reference) {
  final Element? callee;
  final String name;
  final Expression? target;
  switch (reference) {
    case MethodInvocation():
      callee = reference.methodName.element;
      name = reference.methodName.name;
      target = reference.target;
    case Identifier():
      callee = reference.element;
      name = reference.name;
      target = null;
    default:
      return null;
  }
  if (callee is! ExecutableElement || !callee.isExternal) return null;
  if (goNameOf(callee) == null) {
    return 'external "$name" has no @GoName annotation '
        '(see docs/writing_bindings.md)';
  }
  if (goImportOf(callee.library) == null) {
    return 'external "$name" is declared in a library without a @GoImport '
        'annotation (see docs/writing_bindings.md)';
  }
  if (callee is GetterElement && !callee.isStatic) {
    return 'external getter "$name" must be top-level or static to refer to '
        'a Go constant (see docs/writing_bindings.md)';
  }
  if (target != null) {
    if (!isGoType(target.staticType)) {
      return 'method "$name" is called on '
          '"${target.staticType?.getDisplayString() ?? '?'}", which is not a '
          '@GoType class';
    }
    return 'binding method "$name" must be called on a local variable '
        'holding a @GoType value';
  }
  return null;
}

/// The Dart types a local, an argument, or a binding result may have. Each
/// maps onto exactly one Go type (`docs/mapping.md`, "Type mapping table"),
/// so values of these types are passed to Go verbatim.
bool _isSupportedType(DartType? type) =>
    type != null &&
    (type.isDartCoreInt ||
        type.isDartCoreDouble ||
        type.isDartCoreBool ||
        type.isDartCoreString ||
        isGoType(type));

const _supportedTypesLabel = 'int, double, bool, String, and @GoType binding';

/// Checks [expression] in value position (a local's initializer, a binding
/// argument, an interpolated value): it must be something the generator can
/// emit as a single Go expression without helper code — a literal, a local,
/// a binding call, or a reference to a Go constant.
List<UnsupportedSyntaxError> _checkExpression(
  ResolvedUnitResult result,
  Expression expression,
) {
  if (expression is IntegerLiteral ||
      expression is DoubleLiteral ||
      expression is BooleanLiteral ||
      expression is SimpleStringLiteral) {
    return const [];
  }
  if (expression is Identifier) {
    if (expression.element is LocalVariableElement) return const [];
    if (_constantBindingOf(expression) != null) return const [];
    final bindingProblem = _describeBindingProblem(expression);
    if (bindingProblem != null) {
      return [_error(result, expression.offset, bindingProblem)];
    }
  }
  if (expression is MethodInvocation) {
    if (_bindingOf(expression) != null) {
      return _checkBoundCall(result, expression);
    }
    final bindingProblem = _describeBindingProblem(expression);
    if (bindingProblem != null) {
      return [_error(result, expression.offset, bindingProblem)];
    }
  }
  return [
    _error(
      result,
      expression.offset,
      'expression "${_expressionLabel(expression)}" is not supported in v0.1 '
      'minimal scope (only int/double/bool/String literals, local variables, '
      'binding calls, and Go constant references)',
    ),
  ];
}

/// The `@GoName` binding behind a reference to a Go constant or package
/// variable: an `external` top-level getter (`red`) or an `external static`
/// getter on a `@GoType` class (`Button.a`). Instance getters are not
/// bindings; a Go method that returns a value is declared as a method.
GoBinding? _constantBindingOf(Identifier reference) {
  final element = reference.element;
  if (element is! GetterElement || !element.isStatic) return null;
  return goBindingOf(element);
}

/// Arguments to binding calls are checked like any other value expression;
/// their Dart types already match the `external` signature, so the Go call
/// type-checks whenever the binding's Go signature matches its Dart one.
List<UnsupportedSyntaxError> _checkBoundCall(
  ResolvedUnitResult result,
  MethodInvocation call,
) {
  final errors = <UnsupportedSyntaxError>[];
  for (final arg in call.argumentList.arguments) {
    errors.addAll(_checkExpression(result, arg));
  }
  return errors;
}

List<UnsupportedSyntaxError> _checkPrintCall(
  ResolvedUnitResult result,
  MethodInvocation call,
) {
  final args = call.argumentList.arguments;
  if (args.length != 1) {
    return [
      _error(result, call.offset,
          'print() must be called with exactly one argument'),
    ];
  }
  final arg = args.single;
  if (arg is StringInterpolation) {
    final errors = <UnsupportedSyntaxError>[];
    for (final element in arg.elements) {
      if (element is! InterpolationExpression) continue;
      final inner = element.expression;
      final type = inner.staticType;
      if (type == null ||
          !(type.isDartCoreInt ||
              type.isDartCoreBool ||
              type.isDartCoreString)) {
        errors.add(
          _error(
            result,
            inner.offset,
            'string interpolation of "${type?.getDisplayString() ?? '?'}" is '
            'not supported yet (only int, bool, and String)',
          ),
        );
        continue;
      }
      errors.addAll(_checkExpression(result, inner));
    }
    return errors;
  }
  final type = arg.staticType;
  if (type == null || !type.isDartCoreString) {
    return [
      _error(
        result,
        arg.offset,
        'print() argument must be a String (got '
        '"${type?.getDisplayString() ?? '?'}"); other types are not '
        'converted yet',
      ),
    ];
  }
  return _checkExpression(result, arg);
}

List<UnsupportedSyntaxError> _checkSleepCall(
  ResolvedUnitResult result,
  MethodInvocation call,
) {
  final args = call.argumentList.arguments;
  if (args.length != 1) {
    return [
      _error(result, call.offset,
          'sleep() must be called with exactly one argument'),
    ];
  }

  final arg = args.single;
  if (arg is! InstanceCreationExpression) {
    return [
      _error(result, arg.offset,
          'sleep() argument must be a Duration(...) literal'),
    ];
  }

  final creation = arg;
  if (creation.constructorName.type.name.lexeme != 'Duration') {
    return [
      _error(
        result,
        creation.offset,
        'sleep() argument must construct dart:core Duration, got '
        '"${creation.constructorName.type.name.lexeme}"',
      ),
    ];
  }

  const supportedFields = {
    'days',
    'hours',
    'minutes',
    'seconds',
    'milliseconds',
    'microseconds'
  };
  final errors = <UnsupportedSyntaxError>[];
  for (final durationArg in creation.argumentList.arguments) {
    if (durationArg is! NamedExpression ||
        !supportedFields.contains(durationArg.name.label.name)) {
      errors.add(
        _error(
          result,
          durationArg.offset,
          'Duration(...) must use named arguments from $supportedFields',
        ),
      );
      continue;
    }
    if (durationArg.expression is! IntegerLiteral) {
      errors.add(
        _error(
          result,
          durationArg.offset,
          'Duration(...) argument "${durationArg.name.label.name}" must be an '
          'integer literal',
        ),
      );
    }
  }
  return errors;
}

UnsupportedSyntaxError _error(
    ResolvedUnitResult result, int offset, String reason) {
  final location = result.lineInfo.getLocation(offset);
  return UnsupportedSyntaxError(
    filePath: result.path,
    line: location.lineNumber,
    column: location.columnNumber,
    reason: reason,
  );
}

String _declarationLabel(CompilationUnitMember declaration) =>
    _stripImpl(declaration);

String _statementLabel(Statement statement) => _stripImpl(statement);

String _expressionLabel(Expression expression) => _stripImpl(expression);

/// AST node runtime types are the `...Impl` classes that implement the
/// public `...` interfaces (e.g. `IfStatementImpl implements IfStatement`);
/// strip the suffix so error messages read naturally.
String _stripImpl(Object node) {
  final name = node.runtimeType.toString();
  return name.endsWith('Impl') ? name.substring(0, name.length - 4) : name;
}
