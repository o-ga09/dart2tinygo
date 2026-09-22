# dart2tinygo (package)

**Languages:** English | [日本語](./README.ja.md)

[![pub package](https://img.shields.io/pub/v/dart2tinygo.svg)](https://pub.dev/packages/dart2tinygo)

The CLI and the Dart → Go transpiler engine itself.

- `bin/`: CLI entry point (`build`, `check`, and `flash` implemented)
- `lib/src/frontend/`: Parsing and resolved AST retrieval (implemented, via `package:analyzer`'s `AnalysisContextCollection`)
- `lib/src/checker/`: Detection and error reporting for unsupported syntax (implemented for the v0.1 minimal subset)
- `lib/src/ir/`: Intermediate representation (optional, not used yet — the backend walks the resolved AST directly)
- `lib/src/backend/`: Go code generation (implemented for the v0.1 minimal subset)
- `test/golden/`: Golden tests comparing `*.dart` input to `*.go` expected output

**Status:** the v0.1 minimal subset is implemented — a single `void main()`
with `int` locals, `while (true)`, `print(...)`, and `sleep(Duration(...))`.
See [`docs/supported_features.md`](../../docs/supported_features.md) for the
exact scope and [`docs/mapping.md`](../../docs/mapping.md) for the
conversion rules.

```
dart run bin/dart2tinygo.dart check <entry.dart>
dart run bin/dart2tinygo.dart build <entry.dart> [-o out_dir]
dart run bin/dart2tinygo.dart flash <entry.dart> --target=<tinygo-target> [-o out_dir] [--port=<port>]
```

See [`CONTRIBUTING.md`](../../CONTRIBUTING.md) for the design principles and workflow.
