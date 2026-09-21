# Supported language features

**Languages:** English | [日本語](./supported_features.ja.md)

Any PR that adds a language feature must update this table.

## v0.1

| Feature | Status |
| --- | --- |
| Types: `int` | Implemented (minimal: `int`-typed locals only) |
| Types: `double` / `bool` / `String` | Not implemented |
| `var`, type inference | Implemented (minimal: `var x = <int literal>;` only) |
| `final` / `const` locals | Partial: the keyword is ignored, so `final`/`const` are accepted on the same initializers as `var` (an `int` literal or a binding call) and emitted as `x := ...` |
| Top-level functions, `main` | Implemented (minimal: a single parameterless `void main()`, no other top-level functions) |
| `while` | Implemented (minimal: `while (true)` only, no nesting) |
| `if` / `for` / `switch` | Not implemented |
| `print` | Implemented (minimal: string literal or interpolation of `int` locals) |
| String interpolation | Implemented for `int`; other types not implemented |
| Cascade `..` | Not implemented |
| `Duration` and `sleep` | Implemented (`dart:io` `sleep()`, `Duration(days:/hours:/minutes:/seconds:/milliseconds:/microseconds:)`) |
| Bindings via annotations | Implemented (minimal: `@GoImport` / `@GoName` / `@GoType`; calls to external top-level functions and to methods on `@GoType` locals, with int/String literal or int local arguments — see [`writing_bindings.md`](./writing_bindings.md)) |
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
