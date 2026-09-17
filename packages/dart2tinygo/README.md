# dart2tinygo (package)

**Languages:** English | [日本語](./README.ja.md)

The CLI and the Dart → Go transpiler engine itself.

- `bin/`: CLI entry point (`build` / `flash` / `check`)
- `lib/src/frontend/`: Parsing and resolved AST retrieval
- `lib/src/checker/`: Detection and error reporting for unsupported syntax
- `lib/src/ir/`: Intermediate representation (optional)
- `lib/src/backend/`: Go code generation
- `test/golden/`: Golden tests comparing `*.dart` input to `*.go` expected output

Not implemented yet (skeleton only). See [`CONTRIBUTING.md`](../../CONTRIBUTING.md) for the design principles and workflow.
