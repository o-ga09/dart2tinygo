# tinygo_machine (package)

**Languages:** English | [日本語](./README.ja.md)

Board-agnostic bindings corresponding to TinyGo's `machine` package (GPIO, time, LED, etc.).

Following the design principle of not putting board-specific code into the core (`packages/dart2tinygo`), this package only deals with functionality that TinyGo provides in common. Board-specific bindings live in separate repositories (e.g. `package:wio_terminal`).

Not implemented yet (skeleton only).
