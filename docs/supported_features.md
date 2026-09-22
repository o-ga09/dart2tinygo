# Supported language features

**Languages:** English | [日本語](./supported_features.ja.md)

Any PR that adds a language feature must update this table.

## v0.1

| Feature | Status |
| --- | --- |
| Types: `int` | Implemented (locals, literals, binding results, `+`/`-`/`*`/`~/`/`%`, unary `-`, compound assignment, `.toDouble()`) |
| Types: `double` | Implemented (locals, literals, binding results, `+`/`-`/`*`/`/`, unary `-`, compound assignment, `.toInt()`/`.round()`, string interpolation) |
| Types: `bool` | Partial: locals, literals, binding results/arguments, comparison/logical operators |
| Types: `String` | Implemented (locals, literals, binding results/arguments, comparison, `+` concatenation, `.length`, `.codeUnits`, `.substring()`, `String.fromCharCodes()`) |
| Types: `List<int>` | Implemented (maps to Go `[]byte` — see [`mapping.md`](./mapping.md#listint-decided-2026-09-22-implemented); literals, index read/write, `.length`, `.add()`; other element types not implemented) |
| `var`, type inference | Implemented (minimal: `var x = <literal or binding call>;`) |
| `final` / `const` locals | Partial: the keyword is ignored, so `final`/`const` are accepted on the same initializers as `var` and emitted as `x := ...` |
| Top-level functions, `main` | Implemented — a single parameterless `void main()`, plus any number of other top-level functions with positional parameters, `int`/`double`/`bool`/`String`/`List<int>`/`@GoType`/`void` types, block or expression (`=>`) bodies, `return`, recursion, and forward references. Named/optional/default-valued parameters not implemented (see [`mapping.md`](./mapping.md)) |
| `while` | Implemented (any `bool` condition, e.g. `while (count < 10)`; nesting allowed) |
| `for` (C-style) | Implemented (`for (var i = <init>; cond; updater)`; exactly one declared loop variable and one updater — Go's post-clause is a single statement; `for-in` not implemented) |
| `break` / `continue` | Implemented (unlabeled only) |
| `x += y` / `-=` / `*=` | Implemented (`int`/`int` or `double`/`double` only) |
| `x ~/= y` / `%=` | Implemented (`int` only; `~/=` is `x /= y`, `%=` is `x = dartrt.Mod(x, y)`) |
| `x /= y` | Implemented (`double` only — Dart's `/` always returns `double`, so `int /= ...` isn't valid Dart to begin with; use `~/=` for `int`) |
| Arithmetic `a + b` / `- ` / `*` / `/` / `~/` / `%` | Implemented (`+`/`-`/`*` on matching `int`/`int` or `double`/`double`, or `String`/`String` for `+`; `~/`/`%` on `int`; `/` on `double`) |
| `int` ⇄ `double` conversion: `.toDouble()` / `.toInt()` / `.round()` | Implemented (`.toDouble()` on `int`; `.toInt()`/`.round()` on `double`) |
| `if` / `else if` / `else` | Implemented (block-bodied branches; loops and `if` may nest freely) |
| Comparison (`==`/`!=`/`<`/`<=`/`>`/`>=`) and logical (`&&`/`\|\|`/`!`) operators | Implemented (`==`/`!=` on matching `int`/`double`/`bool`/`String`; `<`/`<=`/`>`/`>=` on matching `int`/`int` or `double`/`double`; `&&`/`\|\|`/`!` on `bool`) |
| `switch` | Implemented (`int`/`String`/`bool` expressions only; constant-value cases, `default`; consecutive empty cases group into Go's `case a, b:`; guards (`case ... when ...`) and destructuring patterns not implemented) |
| `print` | Implemented (any `String` expression, or a string interpolation) |
| String interpolation | Implemented for `int` / `double` / `bool` / `String` expressions |
| `Duration` and `sleep` | Implemented (`dart:io` `sleep()`, `Duration(days:/hours:/minutes:/seconds:/milliseconds:/microseconds:)`) |
| Bindings via annotations | Implemented (`@GoImport` / `@GoName` / `@GoType`; calls to external top-level functions and to methods on a `@GoType` receiver — a local, or (method chaining, any depth) another binding call's result — returning `int`/`double`/`bool`/`String`/`@GoType`, arguments of those types, and Go constants via `external` getters — see [`writing_bindings.md`](./writing_bindings.md)) |
| Cascade `..` | Implemented, on a `@GoType` binding value only (`newDisplay()..clear()..drawText(...)`); every section must be a bare `..method(args)` binding call, as a statement or a local's initializer |
| Common Go runtime (`dartrt`) | Implemented (`packages/dart2tinygo/go/`, imported only when used); `Mod` is wired into `%`/`%=`, `FormatDouble` into `double` string interpolation |
| `tinygo_machine`: LED, GPIO in/out, sleep | Not implemented |

See [`docs/mapping.md`](./mapping.md) for the exact Dart → Go rules, and
`packages/dart2tinygo/test/golden/` for a worked example
(`minimal_blink.dart` / `.go`).

## v0.2

| Feature | Status |
| --- | --- |
| Classes (fields, constructors, methods; no inheritance) | Not implemented |
| `List<T>` → Go slice | Not implemented |
| `enum` | Not implemented |
| Bitwise operations, `int.toSigned(n)` | Not implemented |

## Future (depending on demand)

- Inheritance, `mixin`, interfaces
- Generics
- Exceptions
- `async` / `await`, `Timer`
- `Map`, full closure support
