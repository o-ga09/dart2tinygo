# CLAUDE.md

Guidance for Claude Code (and other AI agents, via `AGENTS.md`, a symlink to this file) working in this repository.

## What this project is

`dart2tinygo` is an OSS transpiler that converts a subset of Dart into TinyGo source code so it can run on microcontrollers. It does not aim to implement all of Dart — only the subset useful for embedded development.

## Non-negotiable design principles

- **Never put board-specific knowledge into the core** (`packages/dart2tinygo`). Board support belongs in separate binding packages, declared from the Dart side via annotations (`@GoImport` / `@GoName` / `@GoType`). If a board- or runtime-specific need comes up, look for a way to express it through annotations or config before touching the core.
- When a design choice is ambiguous, prioritize in this order: **correctness of the conversion > binary size > readability of the generated code**.
- Do not use `fmt.Sprintf` for string interpolation in generated Go code — concatenate with `strconv` etc. based on type, to avoid bloating the TinyGo binary.
- Unsupported syntax should be detected and reported up front (file, line, reason) by the checker, not discovered mid-conversion.

## Working in this repo

- See [`CONTRIBUTING.md`](./CONTRIBUTING.md) for the feature-addition workflow, golden test conventions, and pre-PR checklist.
- When you add or change a language feature in the same PR:
  - Add/update golden tests under `packages/dart2tinygo/test/golden/`.
  - Update [`docs/supported_features.md`](./docs/supported_features.md) (**and** its Japanese counterpart `docs/supported_features.ja.md`).
  - Once a conversion rule is decided, record it in [`docs/mapping.md`](./docs/mapping.md) (**and** `docs/mapping.ja.md`).
  - Once a binding annotation API is decided, record it in [`docs/writing_bindings.md`](./docs/writing_bindings.md) (**and** `docs/writing_bindings.ja.md`).

## Documentation language convention

Every document in this repo is maintained in English and Japanese as a pair:

- English is the default filename (e.g. `README.md`, `docs/mapping.md`).
- Japanese is the same name with a `.ja.md` suffix (e.g. `README.ja.md`, `docs/mapping.ja.md`).
- Each file starts with a language-switcher line linking to its counterpart, e.g. `**Languages:** English | [日本語](./mapping.ja.md)`.
- When you edit one language's content, update the other language's file in the same change so they don't drift.

## Repository layout

```
packages/
  dart2tinygo/         # CLI + transpiler engine (core, no board-specific code)
  tinygo_annotations/  # @GoImport / @GoName / @GoType annotations
  tinygo_machine/      # Board-agnostic bindings for TinyGo's common machine package
  wio_terminal/        # Seeed Wio Terminal binding: Dart annotations + Go runtime in go/
examples/               # Samples (hello_wioterminal, blinky, button_led)
docs/                   # Supported features, conversion rules, binding guide
```
