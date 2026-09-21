# dart2tinygo

**Languages:** English | [日本語](./README.ja.md)

An OSS transpiler that converts a subset of Dart into TinyGo source code, so it can run on microcontrollers.

> **Status:** Early scaffolding. The v0.1 minimal transpile is implemented — a
> single `void main()` with `int` locals, `while (true)`, `print(...)`, and
> `sleep(Duration(...))`. See [supported features](./docs/supported_features.md)
> for the exact scope.

## What is this?

- Lets Flutter/Dart developers program microcontrollers while keeping the Dart authoring experience (IDE completion, type checking, lints).
- Targets the many boards TinyGo supports (Wio Terminal, Raspberry Pi Pico, micro:bit, etc.).
- **Does not aim to implement Dart in full.** It focuses on the subset that's useful for embedded development.

See [`CONTRIBUTING.md`](./CONTRIBUTING.md) for the design principles behind this project.

## Repository layout

```
packages/
  dart2tinygo/         # CLI + transpiler engine
  tinygo_annotations/  # Annotations for bindings (@GoImport / @GoName / @GoType)
  tinygo_machine/       # Board-agnostic bindings for TinyGo's common machine package
examples/               # Samples (blinky, etc.)
docs/                   # Supported features, conversion rules, how to write bindings
```

## Documentation

- [Supported language features](./docs/supported_features.md)
- [Dart → Go conversion rules](./docs/mapping.md)
- [Writing bindings](./docs/writing_bindings.md)

## Contributing

Issues and PRs are welcome. See [`CONTRIBUTING.md`](./CONTRIBUTING.md) for the development workflow, and [`CODE_OF_CONDUCT.md`](./CODE_OF_CONDUCT.md) for our community standards.

## Security

See [`SECURITY.md`](./SECURITY.md) for how to report a vulnerability.

## License

[BSD-3-Clause](./LICENSE)
