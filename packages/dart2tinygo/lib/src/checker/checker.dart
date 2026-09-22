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

/// v0.1 minimal scope only: a single `void main()` plus other top-level
/// functions (positional parameters only, `return`), all containing
/// `int`/`double`/`bool`/`String`/`List<int>` locals, `while (cond)`, a
/// single-variable C-style `for`, `break`/`continue`, `if`/`else if`/
/// `else`, comparison (`==`/`!=`/`</`<=`/`>`/`>=`), logical (`&&`/`||`/
/// `!`), arithmetic (`+`/`-`/`*`/`~/`/`%`/`/`, `int`/`double`/`String` not
/// mixed), compound assignment (`+=`/`-=`/`*=`/`/=`/`%=`/`~/=`), `int`⇄
/// `double` conversion (`.toDouble()`/`.toInt()`/`.round()`), and `String`/
/// `List<int>` operations, `print(...)`, `sleep(Duration(...))`, and calls
/// into annotation bindings (`@GoImport` / `@GoName` / `@GoType`, see
/// `docs/writing_bindings.md`). Everything else is reported here, up
/// front, rather than discovered mid-conversion.
List<UnsupportedSyntaxError> checkEntryPoint(ResolvedUnitResult result) {
  final errors = <UnsupportedSyntaxError>[];
  final unit = result.unit;

  FunctionDeclaration? mainDecl;
  final functions = <FunctionDeclaration>[];
  for (final declaration in unit.declarations) {
    if (declaration is FunctionDeclaration) {
      functions.add(declaration);
      if (declaration.name.lexeme == 'main') {
        if (mainDecl != null) {
          errors.add(_error(
              result, declaration.offset, 'duplicate main() declaration'));
        } else {
          mainDecl = declaration;
        }
      }
      continue;
    }
    errors.add(
      _error(
        result,
        declaration.offset,
        'top-level "${_declarationLabel(declaration)}" is not supported yet; '
        'v0.1 minimal scope only supports top-level functions and a single '
        'void main()',
      ),
    );
  }

  if (mainDecl == null) {
    errors.add(_error(result, 0, 'no top-level void main() found'));
    return errors;
  }

  // Checked in source order (not "main first"), so errors read top to
  // bottom the way the file does; recursion and forward references between
  // functions are fine either way, since neither the checker nor Go cares
  // about declaration order.
  for (final function in functions) {
    if (identical(function, mainDecl)) {
      errors.addAll(_checkMainDeclaration(result, function));
    } else {
      errors.addAll(_checkFunctionDeclaration(result, function));
    }
  }

  return errors;
}

List<UnsupportedSyntaxError> _checkMainDeclaration(
  ResolvedUnitResult result,
  FunctionDeclaration mainDecl,
) {
  final errors = <UnsupportedSyntaxError>[];

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
    errors.addAll(_checkStatement(result, statement, insideLoop: false));
  }

  return errors;
}

/// A top-level function other than `main`: plain positional parameters
/// (no named, optional, or default-valued parameters — Go has no
/// equivalent), a supported (or `void`) return type, and a body that's
/// either a block — checked the same way `main`'s is, plus `return` — or
/// an expression (`=> ...`). Recorded in `docs/mapping.md`.
List<UnsupportedSyntaxError> _checkFunctionDeclaration(
  ResolvedUnitResult result,
  FunctionDeclaration declaration,
) {
  final errors = <UnsupportedSyntaxError>[];
  final name = declaration.name.lexeme;

  final returnType = declaration.returnType?.type;
  final isVoidReturn = returnType == null || returnType is VoidType;
  if (!isVoidReturn && !_isSupportedType(returnType)) {
    errors.add(
      _error(
        result,
        declaration.returnType?.offset ?? declaration.offset,
        'function "$name" has return type '
        '"${returnType.getDisplayString()}", but only void or '
        '$_supportedTypesLabel are supported',
      ),
    );
  }

  for (final parameter
      in declaration.functionExpression.parameters?.parameters ??
          const <FormalParameter>[]) {
    if (parameter is! SimpleFormalParameter) {
      errors.add(
        _error(
          result,
          parameter.offset,
          'function "$name" parameter "${parameter.name?.lexeme ?? '?'}" '
          'must be a plain positional parameter in v0.1 minimal scope (no '
          'named, optional, or default-valued parameters)',
        ),
      );
      continue;
    }
    final paramType = parameter.declaredFragment?.element.type;
    if (!_isSupportedType(paramType)) {
      errors.add(
        _error(
          result,
          parameter.offset,
          'function "$name" parameter "${parameter.name?.lexeme ?? '?'}" '
          'has type "${paramType?.getDisplayString() ?? '?'}", but only '
          '$_supportedTypesLabel are supported',
        ),
      );
    }
  }

  final body = declaration.functionExpression.body;
  if (body is ExpressionFunctionBody) {
    if (isVoidReturn) {
      // `void f() => expr;` behaves like a single statement, not a value
      // expression: the generator emits `expr` as its own statement, with
      // no `return` (Go rejects `return <value>` in a function with no
      // declared return type).
      errors.addAll(_checkStatementExpression(result, body.expression));
    } else {
      errors.addAll(_checkExpression(result, body.expression));
    }
  } else if (body is BlockFunctionBody) {
    for (final statement in body.block.statements) {
      errors.addAll(_checkStatement(result, statement, insideLoop: false));
    }
  } else {
    errors.add(
      _error(
        result,
        body.offset,
        'function "$name" must have a block body { ... } or an expression '
        'body (=> ...)',
      ),
    );
  }

  return errors;
}

/// [insideLoop] tracks whether [statement] is (directly or via `if`) inside
/// a `while`/`for` body, which is all `break`/`continue` need to know:
/// loops themselves may nest freely, so unlike the old "no nested loops"
/// restriction this is no longer a gate on `while`/`for` — see #8.
List<UnsupportedSyntaxError> _checkStatement(
  ResolvedUnitResult result,
  Statement statement, {
  required bool insideLoop,
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

    case WhileStatement():
      errors.addAll(_checkBoolCondition(result, statement.condition, 'while'));
      final body = statement.body;
      if (body is! Block) {
        errors.add(
            _error(result, body.offset, 'while body must be a block: { ... }'));
      } else {
        for (final inner in body.statements) {
          errors.addAll(_checkStatement(result, inner, insideLoop: true));
        }
      }

    case ForStatement():
      errors.addAll(_checkForStatement(result, statement));

    case BreakStatement():
      errors.addAll(_checkLoopJump(result, statement,
          statement.breakKeyword.lexeme, statement.label, insideLoop));

    case ContinueStatement():
      errors.addAll(_checkLoopJump(result, statement,
          statement.continueKeyword.lexeme, statement.label, insideLoop));

    case IfStatement():
      errors
          .addAll(_checkIfStatement(result, statement, insideLoop: insideLoop));

    case SwitchStatement():
      errors.addAll(
          _checkSwitchStatement(result, statement, insideLoop: insideLoop));

    case ReturnStatement():
      // Whether a bare `return;` is required (void) or a value is required
      // (non-void) is left to Dart's own analyzer, matching the project's
      // existing "no casts" precedent of not re-deriving type compatibility
      // dart2tinygo can already see was already enforced. Only the return
      // value's own expression, if present, needs checking here.
      final value = statement.expression;
      if (value != null) {
        errors.addAll(_checkExpression(result, value));
      }

    default:
      errors.add(
        _error(
          result,
          statement.offset,
          '"${_statementLabel(statement)}" is not supported in v0.1 minimal '
          'scope (only locals, while/for, break/continue, if/else if/else, '
          'return, print(...), sleep(...), and binding calls)',
        ),
      );
  }

  return errors;
}

List<UnsupportedSyntaxError> _checkLoopJump(
  ResolvedUnitResult result,
  Statement statement,
  String keyword,
  SimpleIdentifier? label,
  bool insideLoop,
) {
  if (label != null) {
    return [
      _error(result, statement.offset,
          'labeled "$keyword" is not supported in v0.1 minimal scope'),
    ];
  }
  if (!insideLoop) {
    return [
      _error(
          result, statement.offset, '"$keyword" outside of a while/for loop'),
    ];
  }
  return const [];
}

/// `for (var i = <init>; <cond>; <updater>) { ... }`: v0.1 minimal scope
/// only covers the C-style form with exactly one declared loop variable, a
/// required condition, and exactly one updater — the shape Go's own `for`
/// syntax can represent directly (Go's post-clause is a single simple
/// statement, unlike Dart/C's comma-separated updater list). `for-in` and
/// `for (i = 0; ...; ...)` (reusing an existing variable) are out of scope.
List<UnsupportedSyntaxError> _checkForStatement(
  ResolvedUnitResult result,
  ForStatement statement,
) {
  final parts = statement.forLoopParts;
  if (parts is! ForPartsWithDeclarations) {
    final reason = parts is ForEachParts
        ? 'for-in loops are not supported in v0.1 minimal scope'
        : 'a for-loop initializer must declare the loop variable (e.g. '
            '"for (var i = 0; ...)"), reusing an existing variable is not '
            'supported in v0.1 minimal scope';
    return [_error(result, parts.offset, reason)];
  }

  final errors = <UnsupportedSyntaxError>[];

  final declared = parts.variables.variables;
  if (declared.length != 1) {
    errors.add(
      _error(
        result,
        parts.variables.offset,
        'a for-loop initializer must declare exactly one variable in v0.1 '
        'minimal scope',
      ),
    );
  }
  for (final variable in declared) {
    final initializer = variable.initializer;
    if (initializer == null) {
      errors.add(
        _error(
          result,
          variable.offset,
          'for-loop variable "${variable.name.lexeme}" must have an '
          'initializer',
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
          'for-loop variable "${variable.name.lexeme}" has type '
          '"${type?.getDisplayString() ?? '?'}", but only '
          '$_supportedTypesLabel locals are supported',
        ),
      );
      continue;
    }
    errors.addAll(_checkExpression(result, initializer));
  }

  final condition = parts.condition;
  if (condition == null) {
    errors.add(
      _error(
        result,
        parts.leftSeparator.offset,
        'a for-loop must have a condition in v0.1 minimal scope (an '
        'infinite for-loop is not supported; use while (true) instead)',
      ),
    );
  } else {
    errors.addAll(_checkBoolCondition(result, condition, 'for-loop'));
  }

  final updaters = parts.updaters;
  if (updaters.length != 1) {
    errors.add(
      _error(
        result,
        parts.rightSeparator.offset,
        'a for-loop must have exactly one updater in v0.1 minimal scope '
        '(Go\'s for-statement only allows a single post-clause statement)',
      ),
    );
  } else {
    errors.addAll(_checkUpdaterExpression(result, updaters.single));
  }

  final body = statement.body;
  if (body is! Block) {
    errors.add(
        _error(result, body.offset, 'for-loop body must be a block: { ... }'));
  } else {
    for (final inner in body.statements) {
      errors.addAll(_checkStatement(result, inner, insideLoop: true));
    }
  }

  return errors;
}

/// A `while`/`for-loop` condition must be a `bool` expression the generator
/// can emit verbatim, exactly like an `if` condition.
List<UnsupportedSyntaxError> _checkBoolCondition(
  ResolvedUnitResult result,
  Expression condition,
  String contextLabel,
) {
  final errors = _checkExpression(result, condition);
  if (errors.isNotEmpty) return errors;
  final type = condition.staticType;
  if (type == null || !type.isDartCoreBool) {
    return [
      _error(
        result,
        condition.offset,
        '$contextLabel condition has type "${type?.getDisplayString() ?? '?'}", '
        'but must be a bool expression',
      ),
    ];
  }
  return const [];
}

/// A for-loop updater or a compound-assignment statement: `x++`/`x--` on an
/// `int` local, or `x += y` (`+=`/`-=`/`*=`/`/=`) on a matching `int`/`int`
/// or `double`/`double` local/value pair.
List<UnsupportedSyntaxError> _checkUpdaterExpression(
  ResolvedUnitResult result,
  Expression expression,
) {
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
  if (expression is AssignmentExpression) {
    return _checkCompoundAssignment(result, expression);
  }
  return [
    _error(
      result,
      expression.offset,
      '"${_expressionLabel(expression)}" is not a supported for-loop '
      'updater or statement in v0.1 minimal scope (only x++/x--/x+=.../'
      'binding calls)',
    ),
  ];
}

const _compoundAssignmentOperators = {'+=', '-=', '*=', '/=', '%=', '~/='};

/// `%=`/`~/=` only make sense on `int` in v0.1 minimal scope: `%=` goes
/// through `dartrt.Mod` (see [_arithmeticOperators]), which is `int`-only,
/// and Dart's floating-point `~/` isn't implemented.
const _intOnlyCompoundAssignmentOperators = {'%=', '~/='};

/// `/=` only makes sense on `double`: Dart's `/` always returns `double`
/// (`num.operator/`), so `int /= anything` is invalid Dart (a `double`
/// can't be assigned back to an `int` variable) — `~/=` is the truncating
/// counterpart for `int`.
const _doubleOnlyCompoundAssignmentOperators = {'/='};

List<UnsupportedSyntaxError> _checkCompoundAssignment(
  ResolvedUnitResult result,
  AssignmentExpression expression,
) {
  final op = expression.operator.lexeme;
  if (!_compoundAssignmentOperators.contains(op)) {
    return [
      _error(
        result,
        expression.offset,
        'assignment operator "$op" is not supported in v0.1 minimal scope '
        '(only +=/-=/*=//=/%=/~/=)',
      ),
    ];
  }

  final target = expression.leftHandSide;
  if (target is! SimpleIdentifier || expression.readElement is! LocalElement) {
    return [
      _error(result, target.offset, '"$op" target must be a local variable'),
    ];
  }
  // A compound-assignment target is read, not written, at its own AST
  // position, so its type lives on the expression as a
  // `CompoundAssignmentExpression` (`readType`), not on `target.staticType`
  // (which the analyzer leaves `null` for a write-only reference).
  final targetType = expression.readType;
  if (targetType == null ||
      !(targetType.isDartCoreInt || targetType.isDartCoreDouble)) {
    return [
      _error(
        result,
        target.offset,
        '"$op" is only supported on int/double locals, got '
        '"${targetType?.getDisplayString() ?? '?'}"',
      ),
    ];
  }
  if (_intOnlyCompoundAssignmentOperators.contains(op) &&
      !targetType.isDartCoreInt) {
    return [
      _error(
        result,
        target.offset,
        '"$op" is only supported on int locals, got '
        '"${targetType.getDisplayString()}"',
      ),
    ];
  }
  if (_doubleOnlyCompoundAssignmentOperators.contains(op) &&
      !targetType.isDartCoreDouble) {
    return [
      _error(
        result,
        target.offset,
        '"$op" is only supported on double locals in v0.1 minimal scope '
        '(Dart\'s "/" always returns double), got '
        '"${targetType.getDisplayString()}"; did you mean "~/=" for '
        'truncating int division?',
      ),
    ];
  }

  final rhs = expression.rightHandSide;
  final rhsErrors = _checkExpression(result, rhs);
  if (rhsErrors.isNotEmpty) return rhsErrors;
  final rhsType = rhs.staticType;
  final matches = rhsType != null &&
      ((targetType.isDartCoreInt && rhsType.isDartCoreInt) ||
          (targetType.isDartCoreDouble && rhsType.isDartCoreDouble));
  if (!matches) {
    return [
      _error(
        result,
        rhs.offset,
        '"$op" requires the right-hand side to have the same type as the '
        'target ("${targetType.getDisplayString()}"), got '
        '"${rhsType?.getDisplayString() ?? '?'}"',
      ),
    ];
  }
  return const [];
}

/// `if (cond) { ... } else if (cond2) { ... } else { ... }`: the condition
/// must be a `bool` expression the generator can emit as-is, and every
/// branch must be a block. `else if` is Dart's own `elseStatement` being
/// another `IfStatement`, so the else-if chain falls out of recursing on it
/// here. [insideLoop] passes through unchanged: `if` neither enters nor
/// leaves a loop, so `break`/`continue` stay exactly as legal inside its
/// branches as they were outside them.
List<UnsupportedSyntaxError> _checkIfStatement(
  ResolvedUnitResult result,
  IfStatement statement, {
  required bool insideLoop,
}) {
  final errors = <UnsupportedSyntaxError>[
    ..._checkBoolCondition(result, statement.expression, 'if'),
  ];

  final then = statement.thenStatement;
  if (then is! Block) {
    errors
        .add(_error(result, then.offset, 'if branch must be a block: { ... }'));
  } else {
    for (final inner in then.statements) {
      errors.addAll(_checkStatement(result, inner, insideLoop: insideLoop));
    }
  }

  final elseStatement = statement.elseStatement;
  if (elseStatement is IfStatement) {
    // `else if (...) { ... }`.
    errors.addAll(
        _checkIfStatement(result, elseStatement, insideLoop: insideLoop));
  } else if (elseStatement is Block) {
    for (final inner in elseStatement.statements) {
      errors.addAll(_checkStatement(result, inner, insideLoop: insideLoop));
    }
  } else if (elseStatement != null) {
    errors.add(
      _error(
        result,
        elseStatement.offset,
        'else branch must be a block: { ... }',
      ),
    );
  }

  return errors;
}

/// `switch (mode) { case 0: ... case 1: case 2: ... default: ... }`: v0.1
/// minimal scope only covers a `switch` expression of type `int`/`String`/
/// `bool` matched against constant-value cases (Go's `switch` has no pattern
/// matching, guards, or destructuring — `docs/mapping.md`). Dart cases don't
/// fall through, so neither does the generated Go, which is why no
/// `insideSwitch` tracking is needed here: unlike C, a bare `break;` isn't
/// required to end a case, so v0.1 doesn't special-case it inside `switch`
/// (it's still only accepted where `insideLoop` already allows it).
List<UnsupportedSyntaxError> _checkSwitchStatement(
  ResolvedUnitResult result,
  SwitchStatement statement, {
  required bool insideLoop,
}) {
  final errors = <UnsupportedSyntaxError>[];

  final scrutineeType = statement.expression.staticType;
  final scrutineeSupported = scrutineeType != null &&
      (scrutineeType.isDartCoreInt ||
          scrutineeType.isDartCoreString ||
          scrutineeType.isDartCoreBool);
  if (!scrutineeSupported) {
    errors.add(
      _error(
        result,
        statement.expression.offset,
        'switch expression has type '
        '"${scrutineeType?.getDisplayString() ?? '?'}", but only '
        'int/String/bool are supported in v0.1 minimal scope',
      ),
    );
  } else {
    errors.addAll(_checkExpression(result, statement.expression));
  }

  for (final member in statement.members) {
    if (member.labels.isNotEmpty) {
      errors.add(
        _error(
          result,
          member.offset,
          'labeled switch cases are not supported in v0.1 minimal scope',
        ),
      );
    }

    switch (member) {
      case SwitchPatternCase():
        final guardedPattern = member.guardedPattern;
        if (guardedPattern.whenClause != null) {
          errors.add(
            _error(
              result,
              guardedPattern.whenClause!.offset,
              '"case ... when ..." guards are not supported in v0.1 '
              'minimal scope',
            ),
          );
        } else {
          final pattern = guardedPattern.pattern;
          if (pattern is! ConstantPattern) {
            errors.add(
              _error(
                result,
                pattern.offset,
                'case pattern "${_stripImpl(pattern)}" is not supported in '
                'v0.1 minimal scope (only constant int/String/bool values)',
              ),
            );
          } else if (scrutineeSupported) {
            errors.addAll(
                _checkCaseValue(result, pattern.expression, scrutineeType));
          }
        }
      case SwitchDefault():
        break;
      case SwitchCase():
        // The pre-Dart-3 non-pattern case form; the parser always produces
        // SwitchPatternCase for `case <expr>:` today, but SwitchMember is a
        // sealed class with this as a third variant.
        errors.add(
          _error(
            result,
            member.offset,
            'case pattern "${_stripImpl(member)}" is not supported in v0.1 '
            'minimal scope (only constant int/String/bool values)',
          ),
        );
    }

    for (final inner in member.statements) {
      errors.addAll(_checkStatement(result, inner, insideLoop: insideLoop));
    }
  }

  return errors;
}

/// A case value must be a literal matching the switch expression's type
/// exactly — no implicit promotion, matching the "no implicit casts"
/// precedent used throughout (`docs/mapping.md`).
List<UnsupportedSyntaxError> _checkCaseValue(
  ResolvedUnitResult result,
  Expression expression,
  DartType scrutineeType,
) {
  final matches = (scrutineeType.isDartCoreInt &&
          expression is IntegerLiteral) ||
      (scrutineeType.isDartCoreString && expression is SimpleStringLiteral) ||
      (scrutineeType.isDartCoreBool && expression is BooleanLiteral);
  if (!matches) {
    return [
      _error(
        result,
        expression.offset,
        'case value "${_expressionLabel(expression)}" does not match the '
        'switch expression\'s type '
        '"${scrutineeType.getDisplayString()}"; v0.1 minimal scope only '
        'supports constant int/String/bool literals',
      ),
    ];
  }
  return const [];
}

List<UnsupportedSyntaxError> _checkExpressionStatement(
  ResolvedUnitResult result,
  ExpressionStatement statement,
) =>
    _checkStatementExpression(result, statement.expression);

/// An [expression] used the way a statement uses one: its value, if any, is
/// discarded, so only expressions the generator knows how to emit as a
/// standalone Go statement are accepted — not any value expression (e.g. a
/// bare `1 + 2;` is rejected here even though it's fine in value position).
/// Shared by [_checkExpressionStatement] and, for a `void` function's
/// expression body (`void f() => expr;`, which behaves like a single
/// statement — see `_checkFunctionDeclaration`), that body's expression
/// directly.
List<UnsupportedSyntaxError> _checkStatementExpression(
  ResolvedUnitResult result,
  Expression expression,
) {
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

  if (expression is AssignmentExpression) {
    if (expression.leftHandSide is IndexExpression) {
      // `data[i] = v;`: a List<int> index write. Every other assignment
      // target (a bare local) goes through the compound-assignment path,
      // which also handles reporting bare `=` there as unsupported.
      return _checkListIndexWrite(result, expression);
    }
    return _checkCompoundAssignment(result, expression);
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
    final listAdd = _checkListAdd(result, expression);
    if (listAdd != null) return listAdd;
    if (_checkNumConversion(result, expression) != null ||
        _checkStringMethod(result, expression) != null ||
        _isLocalFunctionCall(expression) ||
        _bindingOf(expression) != null ||
        _describeBindingProblem(expression) != null) {
      // A conversion, String method, local function call, or binding call
      // as a statement; a non-void result is discarded.
      return _checkExpression(result, expression);
    }
  }

  return [
    _error(
      result,
      expression.offset,
      'expression "${_expressionLabel(expression)}" is not supported in '
      'v0.1 minimal scope (only x++/x--, x+=.../-=/*=//=, print(...), '
      'sleep(...), and binding calls)',
    ),
  ];
}

/// A call to a top-level Dart function declared in this same file, not an
/// `external` binding — see `docs/mapping.md`, "Top-level functions". Maps
/// 1:1 onto a Go call of the same name.
bool _isLocalFunctionCall(MethodInvocation call) {
  final callee = call.methodName.element;
  return call.target == null &&
      callee is TopLevelFunctionElement &&
      !callee.isExternal;
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
        target.element is! LocalElement ||
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
        _isListOfInt(type) ||
        isGoType(type));

const _supportedTypesLabel =
    'int, double, bool, String, List<int>, and @GoType binding';

/// `List<int>` maps to Go `[]byte` — see the `List<int>` section of
/// `docs/mapping.md`. No other element type is supported —
/// `List<double>`/`List<String>`/etc. stay out of v0.1 minimal scope.
bool _isListOfInt(DartType? type) {
  if (type is! InterfaceType || !type.isDartCoreList) return false;
  final args = type.typeArguments;
  return args.length == 1 && args.single.isDartCoreInt;
}

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
    if (expression.element is LocalElement) return const [];
    final builtinGetter = _checkBuiltinGetter(result, expression);
    if (builtinGetter != null) return builtinGetter;
    if (_constantBindingOf(expression) != null) return const [];
    final bindingProblem = _describeBindingProblem(expression);
    if (bindingProblem != null) {
      return [_error(result, expression.offset, bindingProblem)];
    }
  }
  if (expression is PropertyAccess) {
    final builtinGetter = _checkBuiltinGetter(result, expression);
    if (builtinGetter != null) return builtinGetter;
  }
  if (expression is MethodInvocation) {
    final conversion = _checkNumConversion(result, expression);
    if (conversion != null) return conversion;
    final stringMethod = _checkStringMethod(result, expression);
    if (stringMethod != null) return stringMethod;
    if (_isLocalFunctionCall(expression) || _bindingOf(expression) != null) {
      return _checkBoundCall(result, expression);
    }
    final bindingProblem = _describeBindingProblem(expression);
    if (bindingProblem != null) {
      return [_error(result, expression.offset, bindingProblem)];
    }
  }
  if (expression is InstanceCreationExpression) {
    final fromCharCodes = _checkFromCharCodes(result, expression);
    if (fromCharCodes != null) return fromCharCodes;
  }
  if (expression is ListLiteral) {
    return _checkListLiteral(result, expression);
  }
  if (expression is IndexExpression) {
    return _checkIndexExpression(result, expression);
  }
  if (expression is ParenthesizedExpression) {
    return _checkExpression(result, expression.expression);
  }
  if (expression is BinaryExpression) {
    return _checkBinaryExpression(result, expression);
  }
  if (expression is PrefixExpression && expression.operator.lexeme == '!') {
    final operand = expression.operand;
    final operandErrors = _checkExpression(result, operand);
    if (operandErrors.isNotEmpty) return operandErrors;
    final type = operand.staticType;
    if (type == null || !type.isDartCoreBool) {
      return [
        _error(
          result,
          operand.offset,
          '"!" operand has type "${type?.getDisplayString() ?? '?'}", but '
          'must be a bool expression',
        ),
      ];
    }
    return const [];
  }
  if (expression is PrefixExpression && expression.operator.lexeme == '-') {
    final operand = expression.operand;
    final operandErrors = _checkExpression(result, operand);
    if (operandErrors.isNotEmpty) return operandErrors;
    final type = operand.staticType;
    if (type == null || !(type.isDartCoreInt || type.isDartCoreDouble)) {
      return [
        _error(
          result,
          operand.offset,
          'unary "-" operand has type "${type?.getDisplayString() ?? '?'}", '
          'but v0.1 minimal scope only supports int/double',
        ),
      ];
    }
    return const [];
  }
  return [
    _error(
      result,
      expression.offset,
      'expression "${_expressionLabel(expression)}" is not supported in v0.1 '
      'minimal scope (only int/double/bool/String literals, local variables, '
      'binding calls, Go constant references, comparisons, logical operators, '
      'and int arithmetic)',
    ),
  ];
}

const _comparisonOperators = {'<', '<=', '>', '>='};
const _equalityOperators = {'==', '!='};
const _logicalOperators = {'&&', '||'};

/// `+`/`-`/`*`: `int`/`int` or `double`/`double` (not mixed). `~/`/`%`:
/// `int` only — `~/` maps to Go's `/` (both truncate toward zero), `%` goes
/// through `dartrt.Mod` because Dart's `%` is never negative, unlike Go's
/// (`docs/mapping.md`, "Numeric semantics"). `/`: `double`/`double` only —
/// Dart's `/` always returns `double` even for two `int`s, which the
/// generator can't reproduce without a cast, so an `int` operand is
/// rejected rather than silently promoted (convert with `.toDouble()`).
const _arithmeticOperators = {'+', '-', '*', '~/', '%', '/'};
const _intOnlyArithmeticOperators = {'~/', '%'};

/// Comparison (`==`/`!=`/`</`<=`/`>`/`>=`), logical (`&&`/`||`), and `int`/
/// `double` arithmetic (`+`/`-`/`*`/`~/`/`%`/`/`) binary operators map 1:1
/// onto Go (or, for `%`, onto `dartrt.Mod`), which uses the same tokens
/// (`docs/mapping.md`). Every other operator (bitwise, `String`
/// concatenation `+`) is out of v0.1 minimal scope.
///
/// To keep the generator cast-free, both operands of a comparison,
/// equality, or arithmetic operator must have the *same* supported type —
/// no implicit `int`/`double` promotion the way Dart's `num` hierarchy
/// allows. `<`/`<=`/`>`/`>=` are further restricted to `int`/`double`,
/// matching Go's ordering operators.
List<UnsupportedSyntaxError> _checkBinaryExpression(
  ResolvedUnitResult result,
  BinaryExpression expression,
) {
  final op = expression.operator.lexeme;
  final isComparison = _comparisonOperators.contains(op);
  final isEquality = _equalityOperators.contains(op);
  final isLogical = _logicalOperators.contains(op);
  final isArithmetic = _arithmeticOperators.contains(op);
  if (!isComparison && !isEquality && !isLogical && !isArithmetic) {
    return [
      _error(
        result,
        expression.offset,
        'binary operator "$op" is not supported in v0.1 minimal scope (only '
        'comparisons ==/!=/</<=/>/>=, logical &&/||, and arithmetic '
        '+, -, *, ~/, %, /)',
      ),
    ];
  }

  final left = expression.leftOperand;
  final right = expression.rightOperand;
  final errors = <UnsupportedSyntaxError>[
    ..._checkExpression(result, left),
    ..._checkExpression(result, right),
  ];
  if (errors.isNotEmpty) return errors;

  final leftType = left.staticType;
  final rightType = right.staticType;

  if (isLogical) {
    if (!(leftType?.isDartCoreBool ?? false) ||
        !(rightType?.isDartCoreBool ?? false)) {
      errors.add(
        _error(
          result,
          expression.offset,
          '"$op" requires bool operands, got '
          '"${leftType?.getDisplayString() ?? '?'}" and '
          '"${rightType?.getDisplayString() ?? '?'}"',
        ),
      );
    }
    return errors;
  }

  if (isArithmetic) {
    if (op == '/') {
      if (!(leftType?.isDartCoreDouble ?? false) ||
          !(rightType?.isDartCoreDouble ?? false)) {
        errors.add(
          _error(
            result,
            expression.offset,
            '"/" requires double operands in v0.1 minimal scope (Dart\'s "/" '
            'always returns double, even for two ints; convert with '
            '.toDouble() first), got "${leftType?.getDisplayString() ?? '?'}" '
            'and "${rightType?.getDisplayString() ?? '?'}"',
          ),
        );
      }
    } else if (_intOnlyArithmeticOperators.contains(op)) {
      if (!(leftType?.isDartCoreInt ?? false) ||
          !(rightType?.isDartCoreInt ?? false)) {
        errors.add(
          _error(
            result,
            expression.offset,
            '"$op" is only supported for int operands in v0.1 minimal scope, '
            'got "${leftType?.getDisplayString() ?? '?'}" and '
            '"${rightType?.getDisplayString() ?? '?'}"',
          ),
        );
      }
    } else {
      final bothInt = (leftType?.isDartCoreInt ?? false) &&
          (rightType?.isDartCoreInt ?? false);
      final bothDouble = (leftType?.isDartCoreDouble ?? false) &&
          (rightType?.isDartCoreDouble ?? false);
      // `+` also does string concatenation, matching Go's own `+`
      // (docs/mapping.md); `-`/`*` have no String meaning in Dart either.
      final bothString = op == '+' &&
          (leftType?.isDartCoreString ?? false) &&
          (rightType?.isDartCoreString ?? false);
      if (!bothInt && !bothDouble && !bothString) {
        errors.add(
          _error(
            result,
            expression.offset,
            '"$op" requires both operands to be int, or both double'
            '${op == '+' ? ', or both String' : ''}, in v0.1 minimal scope, '
            'got "${leftType?.getDisplayString() ?? '?'}" and '
            '"${rightType?.getDisplayString() ?? '?'}"',
          ),
        );
      }
    }
    return errors;
  }

  if (leftType == null ||
      rightType == null ||
      !_sameComparableType(leftType, rightType)) {
    errors.add(
      _error(
        result,
        expression.offset,
        '"$op" requires both operands to have the same type (int, double, '
        'bool, or String), got "${leftType?.getDisplayString() ?? '?'}" and '
        '"${rightType?.getDisplayString() ?? '?'}"',
      ),
    );
    return errors;
  }

  if (isComparison && !(leftType.isDartCoreInt || leftType.isDartCoreDouble)) {
    errors.add(
      _error(
        result,
        expression.offset,
        '"$op" is only supported for int and double operands, got '
        '"${leftType.getDisplayString()}"',
      ),
    );
  }
  return errors;
}

bool _sameComparableType(DartType a, DartType b) =>
    (a.isDartCoreInt && b.isDartCoreInt) ||
    (a.isDartCoreDouble && b.isDartCoreDouble) ||
    (a.isDartCoreBool && b.isDartCoreBool) ||
    (a.isDartCoreString && b.isDartCoreString);

/// The `@GoName` binding behind a reference to a Go constant or package
/// variable: an `external` top-level getter (`red`) or an `external static`
/// getter on a `@GoType` class (`Button.a`). Instance getters are not
/// bindings; a Go method that returns a value is declared as a method.
GoBinding? _constantBindingOf(Identifier reference) {
  final element = reference.element;
  if (element is! GetterElement || !element.isStatic) return null;
  return goBindingOf(element);
}

/// `num` conversion methods bridging `int` and `double`
/// (`docs/mapping.md`): `int.toDouble()` (→ Go `float64(x)`),
/// `double.toInt()` (→ `int(x)`, truncating like Dart's), `double.round()`
/// (→ `int(math.Round(x))`, rounding half away from zero like Dart's).
/// Receiver types are restricted to the direction each conversion actually
/// bridges — `toDouble()` on an already-`double` value, or `toInt()`/
/// `round()` on an already-`int` value, are pointless identities nobody
/// writes in this domain and are rejected rather than generating a
/// redundant cast.
///
/// Returns `null` (not `[]`) when [call] isn't one of these three methods,
/// so the caller falls through to its usual binding-call handling instead
/// of treating every unrecognized call as a conversion error.
List<UnsupportedSyntaxError>? _checkNumConversion(
  ResolvedUnitResult result,
  MethodInvocation call,
) {
  final name = call.methodName.name;
  final target = call.target;
  if (target == null) return null;
  final String requiredType;
  switch (name) {
    case 'toDouble':
      requiredType = 'int';
    case 'toInt':
    case 'round':
      requiredType = 'double';
    default:
      return null;
  }
  // Only treat this as a conversion when the receiver is already int/double
  // — otherwise it's an ordinary (possibly binding) method call that just
  // happens to share one of these names, and the caller's own binding
  // checks should run instead.
  final targetType = target.staticType;
  final looksNumeric = targetType != null &&
      (targetType.isDartCoreInt || targetType.isDartCoreDouble);
  if (!looksNumeric) return null;

  final errors = <UnsupportedSyntaxError>[
    ..._checkExpression(result, target),
  ];
  if (call.argumentList.arguments.isNotEmpty) {
    errors.add(
      _error(result, call.argumentList.offset, '".$name()" takes no arguments'),
    );
  }
  if (errors.isNotEmpty) return errors;

  final matchesRequired = requiredType == 'int'
      ? targetType.isDartCoreInt
      : targetType.isDartCoreDouble;
  if (!matchesRequired) {
    return [
      _error(
        result,
        target.offset,
        '".$name()" requires a $requiredType receiver in v0.1 minimal '
        'scope, got "${targetType.getDisplayString()}"',
      ),
    ];
  }
  return const [];
}

/// `.length` (`String` or `List<int>` receiver) and `.codeUnits` (`String`
/// receiver) are built-in getters, not `@GoName` bindings: `x.length` maps
/// to Go's `len(x)`, `s.codeUnits` to `[]byte(s)` (`docs/mapping.md`). Dart
/// parses these as `PrefixedIdentifier` when the receiver is a bare
/// identifier (`s.length`) and `PropertyAccess` otherwise (`'hi'.length`) —
/// both shapes are handled here.
///
/// Returns `null` (not `[]`) when [expression] isn't one of these two
/// getters, so the caller falls through to its usual identifier/binding
/// handling instead of treating every unrecognized property as an error.
List<UnsupportedSyntaxError>? _checkBuiltinGetter(
  ResolvedUnitResult result,
  Expression expression,
) {
  final Expression target;
  final String name;
  switch (expression) {
    case PrefixedIdentifier():
      target = expression.prefix;
      name = expression.identifier.name;
    case PropertyAccess():
      final propertyTarget = expression.target;
      if (propertyTarget == null) return null;
      target = propertyTarget;
      name = expression.propertyName.name;
    default:
      return null;
  }
  if (name != 'length' && name != 'codeUnits') return null;

  final targetType = target.staticType;
  final isString = targetType?.isDartCoreString ?? false;
  if (name == 'codeUnits' && !isString) return null;
  if (name == 'length' && !isString && !_isListOfInt(targetType)) return null;

  return _checkExpression(result, target);
}

/// `String.fromCharCodes(bytes)` is a named constructor
/// (`InstanceCreationExpression`, the same AST shape as `Duration(...)`),
/// not a static method call — see `docs/mapping.md`. Maps to Go's
/// `string(bytes)` conversion.
///
/// Returns `null` (not `[]`) when [creation] isn't this constructor.
List<UnsupportedSyntaxError>? _checkFromCharCodes(
  ResolvedUnitResult result,
  InstanceCreationExpression creation,
) {
  final typeName = creation.constructorName.type.name.lexeme;
  final constructorName = creation.constructorName.name?.name;
  if (typeName != 'String' || constructorName != 'fromCharCodes') return null;

  final args = creation.argumentList.arguments;
  if (args.length != 1) {
    return [
      _error(
        result,
        creation.offset,
        'String.fromCharCodes(...) must be called with exactly one argument',
      ),
    ];
  }
  final arg = args.single;
  final argErrors = _checkExpression(result, arg);
  if (argErrors.isNotEmpty) return argErrors;
  if (!_isListOfInt(arg.staticType)) {
    return [
      _error(
        result,
        arg.offset,
        'String.fromCharCodes(...) argument must be a List<int>, got '
        '"${arg.staticType?.getDisplayString() ?? '?'}"',
      ),
    ];
  }
  return const [];
}

/// `s.substring(start, [end])` on a `String` receiver, maps to Go's
/// `x[start:end]` (or `x[start:]` with no `end`) slice syntax — byte-
/// indexed, like Go's own strings (`docs/mapping.md`).
///
/// Returns `null` (not `[]`) when [call] isn't `.substring(...)`, so the
/// caller falls through to its usual binding-call handling.
List<UnsupportedSyntaxError>? _checkStringMethod(
  ResolvedUnitResult result,
  MethodInvocation call,
) {
  if (call.methodName.name != 'substring') return null;
  final target = call.target;
  if (target == null) return null;
  final targetType = target.staticType;
  if (targetType == null || !targetType.isDartCoreString) return null;

  final errors = <UnsupportedSyntaxError>[
    ..._checkExpression(result, target),
  ];
  final args = call.argumentList.arguments;
  if (args.isEmpty || args.length > 2) {
    errors.add(
      _error(
        result,
        call.offset,
        '"substring" takes one or two arguments (start, [end])',
      ),
    );
    return errors;
  }
  for (final arg in args) {
    final argErrors = _checkExpression(result, arg);
    if (argErrors.isNotEmpty) {
      errors.addAll(argErrors);
      continue;
    }
    final argType = arg.staticType;
    if (argType == null || !argType.isDartCoreInt) {
      errors.add(
        _error(
          result,
          arg.offset,
          '"substring" arguments must be int, got '
          '"${argType?.getDisplayString() ?? '?'}"',
        ),
      );
    }
  }
  return errors;
}

/// `<int>[1, 2, 3]` (or a plain `[1, 2, 3]` inferred as `List<int>`) maps to
/// Go's `[]byte{1, 2, 3}` — see the `List<int>` section of
/// `docs/mapping.md`. Only literal `Expression` elements are supported — no
/// spreads or `if`/`for` inside the literal.
List<UnsupportedSyntaxError> _checkListLiteral(
  ResolvedUnitResult result,
  ListLiteral literal,
) {
  if (!_isListOfInt(literal.staticType)) {
    return [
      _error(
        result,
        literal.offset,
        'list literal has type '
        '"${literal.staticType?.getDisplayString() ?? '?'}", but only '
        'List<int> is supported in v0.1 minimal scope',
      ),
    ];
  }
  final errors = <UnsupportedSyntaxError>[];
  for (final element in literal.elements) {
    if (element is! Expression) {
      errors.add(
        _error(
          result,
          element.offset,
          '"${_stripImpl(element)}" is not supported inside a list literal',
        ),
      );
      continue;
    }
    errors.addAll(_checkExpression(result, element));
  }
  return errors;
}

/// `data[i]` (read or write): [target] must be a local variable holding a
/// `List<int>` — the same "must be a plain local, not an arbitrary
/// expression" restriction used for binding methods and compound
/// assignment. Shared by [_checkExpression] (read) and
/// [_checkListIndexWrite] (write), since a Dart `IndexExpression` has the
/// same shape either way; only the surrounding `AssignmentExpression`
/// differs.
List<UnsupportedSyntaxError> _checkIndexExpression(
  ResolvedUnitResult result,
  IndexExpression expression,
) {
  final target = expression.target;
  if (target is! SimpleIdentifier ||
      target.element is! LocalElement ||
      !_isListOfInt(target.staticType)) {
    return [
      _error(
        result,
        expression.offset,
        'indexing "[...]" must be on a local variable holding a List<int>',
      ),
    ];
  }
  return _checkExpression(result, expression.index);
}

/// `data[i] = v;`: only plain `=` is supported (no `data[i] += v;` etc.),
/// and `v` must be `int` (Go's `[]byte` element type needs an explicit
/// `byte(v)` cast the generator adds, see `docs/mapping.md`).
List<UnsupportedSyntaxError> _checkListIndexWrite(
  ResolvedUnitResult result,
  AssignmentExpression expression,
) {
  if (expression.operator.lexeme != '=') {
    return [
      _error(
        result,
        expression.offset,
        '"${expression.operator.lexeme}" is not supported on List<int> '
        'indexing in v0.1 minimal scope (only plain "=")',
      ),
    ];
  }
  final indexErrors =
      _checkIndexExpression(result, expression.leftHandSide as IndexExpression);
  if (indexErrors.isNotEmpty) return indexErrors;

  final rhs = expression.rightHandSide;
  final rhsErrors = _checkExpression(result, rhs);
  if (rhsErrors.isNotEmpty) return rhsErrors;
  final rhsType = rhs.staticType;
  if (rhsType == null || !rhsType.isDartCoreInt) {
    return [
      _error(
        result,
        rhs.offset,
        'List<int> index assignment requires an int value, got '
        '"${rhsType?.getDisplayString() ?? '?'}"',
      ),
    ];
  }
  return const [];
}

/// `data.add(v);` as a statement (`List.add` returns `void` in Dart, so it
/// never appears in value position): maps to Go's `data = append(data,
/// byte(v))`.
///
/// Returns `null` (not `[]`) when [call] isn't `.add(...)` on a `List<int>`
/// local, so the caller falls through to its usual binding-call handling.
List<UnsupportedSyntaxError>? _checkListAdd(
  ResolvedUnitResult result,
  MethodInvocation call,
) {
  if (call.methodName.name != 'add') return null;
  final target = call.target;
  if (target is! SimpleIdentifier ||
      target.element is! LocalElement ||
      !_isListOfInt(target.staticType)) {
    return null;
  }
  final args = call.argumentList.arguments;
  if (args.length != 1) {
    return [
      _error(
        result,
        call.offset,
        'add(...) must be called with exactly one argument',
      ),
    ];
  }
  final arg = args.single;
  final argErrors = _checkExpression(result, arg);
  if (argErrors.isNotEmpty) return argErrors;
  final argType = arg.staticType;
  if (argType == null || !argType.isDartCoreInt) {
    return [
      _error(
        result,
        arg.offset,
        'add(...) argument must be int, got '
        '"${argType?.getDisplayString() ?? '?'}"',
      ),
    ];
  }
  return const [];
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
              type.isDartCoreDouble ||
              type.isDartCoreBool ||
              type.isDartCoreString)) {
        errors.add(
          _error(
            result,
            inner.offset,
            'string interpolation of "${type?.getDisplayString() ?? '?'}" is '
            'not supported yet (only int, double, bool, and String)',
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
