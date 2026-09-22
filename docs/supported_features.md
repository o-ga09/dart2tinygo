# Supported language features

**Languages:** English | [日本語](./supported_features.ja.md)

Any PR that adds a language feature must update this table.

## v0.1

| Feature | Status |
| --- | --- |
| Types: `int` | Implemented (locals, literals, binding results; no arithmetic yet) |
| Types: `double` / `bool` / `String` | Partial: locals, literals, binding results/arguments, and (`bool`) comparison/logical operators; no arithmetic or `String` operations yet |
| `var`, type inference | Implemented (minimal: `var x = <literal or binding call>;`) |
| `final` / `const` locals | Partial: the keyword is ignored, so `final`/`const` are accepted on the same initializers as `var` and emitted as `x := ...` |
| Top-level functions, `main` | Implemented (minimal: a single parameterless `void main()`, no other top-level functions) |
| `while` | Implemented (minimal: `while (true)` only, no nesting) |
| `if` / `else if` / `else` | Implemented (block-bodied branches; may nest inside `while` and inside other `if`, but not the other way around — `while` still can't nest) |
| Comparison (`==`/`!=`/`<`/`<=`/`>`/`>=`) and logical (`&&`/`\|\|`/`!`) operators | Implemented (`==`/`!=` on matching `int`/`double`/`bool`/`String`; `<`/`<=`/`>`/`>=` on matching `int`/`int` or `double`/`double`; `&&`/`\|\|`/`!` on `bool`) |
| `for` / `switch` | Not implemented |
| `print` | Implemented (any `String` expression, or a string interpolation) |
| String interpolation | Implemented for `int` / `bool` / `String` expressions; `double` not implemented |
| Cascade `..` | Not implemented |
| `Duration` and `sleep` | Implemented (`dart:io` `sleep()`, `Duration(days:/hours:/minutes:/seconds:/milliseconds:/microseconds:)`) |
| Bindings via annotations | Implemented (`@GoImport` / `@GoName` / `@GoType`; calls to external top-level functions and to methods on `@GoType` locals returning `int`/`double`/`bool`/`String`/`@GoType`, arguments of those types, and Go constants via `external` getters — see [`writing_bindings.md`](./writing_bindings.md)). Chaining on call results not implemented |
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
