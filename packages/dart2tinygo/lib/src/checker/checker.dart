import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
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

/// v0.1 minimal scope only: a single `void main()` containing `int` locals,
/// `while (true)`, `print(...)`, `sleep(Duration(...))`, and calls into
/// annotation bindings (`@GoImport` / `@GoName` / `@GoType`, see
/// `docs/writing_bindings.md`). Everything else is reported here, up front,
/// rather than discovered mid-conversion.
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
        if (variable.initializer == null) {
          errors.add(
            _error(
              result,
              variable.offset,
              'local variable "${variable.name.lexeme}" must have an initializer',
            ),
          );
          continue;
        }
        final initializer = variable.initializer!;
        final type = initializer.staticType;
        if (initializer is MethodInvocation &&
            initializer.target == null &&
            _bindingOf(initializer) != null) {
          // `final display = newDisplay();` — a binding call whose result is
          // a `@GoType` value, kept in a local for later method calls.
          errors.addAll(_checkBoundCall(result, initializer));
          if (!isGoType(type)) {
            errors.add(
              _error(
                result,
                initializer.offset,
                'binding call "${initializer.methodName.name}" returns '
                '"${type?.getDisplayString() ?? '?'}", but only @GoType '
                'classes can be stored in a local',
              ),
            );
          }
          continue;
        }
        if (type == null || !type.isDartCoreInt) {
          errors.add(
            _error(
              result,
              variable.offset,
              'local variable "${variable.name.lexeme}" has type '
              '"${type?.getDisplayString() ?? '?'}", but v0.1 minimal scope '
              'only supports int locals and @GoType binding values',
            ),
          );
        } else if (initializer is! IntegerLiteral) {
          errors.add(
            _error(
              result,
              variable.initializer!.offset,
              'local variable "${variable.name.lexeme}" must be initialized '
              'with an integer literal in v0.1 minimal scope',
            ),
          );
        }
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

/// Explains why [call] looks like a binding call but isn't one, so binding
/// authors get a pointer at the missing annotation rather than a generic
/// "unsupported expression".
String? _describeBindingProblem(MethodInvocation call) {
  final callee = call.methodName.element;
  if (callee is! ExecutableElement || !callee.isExternal) return null;
  final name = call.methodName.name;
  if (goNameOf(callee) == null) {
    return 'external "$name" has no @GoName annotation '
        '(see docs/writing_bindings.md)';
  }
  if (goImportOf(callee.library) == null) {
    return 'external "$name" is declared in a library without a @GoImport '
        'annotation (see docs/writing_bindings.md)';
  }
  final target = call.target;
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

/// Arguments to binding calls are limited to what can be passed to Go
/// verbatim: `int` literals, `String` literals, and `int` locals.
List<UnsupportedSyntaxError> _checkBoundCall(
  ResolvedUnitResult result,
  MethodInvocation call,
) {
  final errors = <UnsupportedSyntaxError>[];
  for (final arg in call.argumentList.arguments) {
    if (arg is IntegerLiteral || arg is SimpleStringLiteral) continue;
    final type = arg.staticType;
    if (arg is SimpleIdentifier &&
        arg.element is LocalVariableElement &&
        type != null &&
        type.isDartCoreInt) {
      continue;
    }
    errors.add(
      _error(
        result,
        arg.offset,
        'binding call "${call.methodName.name}" argument must be an int '
        'literal, a string literal, or an int local variable',
      ),
    );
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
  if (arg is SimpleStringLiteral) {
    return const [];
  }
  if (arg is StringInterpolation) {
    final errors = <UnsupportedSyntaxError>[];
    for (final element in arg.elements) {
      if (element is InterpolationExpression) {
        final inner = element.expression;
        final type = inner.staticType;
        if (inner is! SimpleIdentifier || type == null || !type.isDartCoreInt) {
          errors.add(
            _error(
              result,
              inner.offset,
              'string interpolation only supports int-typed local variables '
              'in v0.1 minimal scope',
            ),
          );
        }
      }
    }
    return errors;
  }
  return [
    _error(
      result,
      arg.offset,
      'print() argument must be a string literal or string interpolation',
    ),
  ];
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
