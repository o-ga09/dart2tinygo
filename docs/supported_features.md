# Supported language features

**Languages:** English | [日本語](./supported_features.ja.md)

Any PR that adds a language feature must update this table.

## v0.1

| Feature | Status |
| --- | --- |
| Types: `int` / `double` / `bool` / `String` | Not implemented |
| `var` / `final` / `const`, type inference | Not implemented |
| Top-level functions, `main` | Not implemented |
| `if` / `for` / `while` / `switch` | Not implemented |
| String interpolation, `print` | Not implemented |
| Cascade `..` | Not implemented |
| `Duration` and `sleep` | Not implemented |
| Bindings via annotations | Not implemented |
| `tinygo_machine`: LED, GPIO in/out, sleep | Not implemented |

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
