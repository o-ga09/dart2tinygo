# Writing bindings

**Languages:** English | [日本語](./writing_bindings.ja.md)

Board-specific support is not put into the core (`packages/dart2tinygo`); it's provided as separate binding packages.
A binding is a Dart package whose public API consists of `external` declarations annotated with `package:tinygo_annotations`, plus a Go package that implements them. The transpiler never sees board code: it only reads the annotations.

## Annotations (decided, implemented)

| Annotation | Where | Meaning |
| --- | --- | --- |
| `@GoImport(path, alias: ...)` | The `library;` directive | The Go import for this library. `alias` is optional; without it Go's default package name (the last path segment) is used. |
| `@GoName(name)` | An `external` top-level function | The fully qualified Go call target, e.g. `'wio.NewDisplay'` (prefix = the `@GoImport` alias). |
| `@GoName(name)` | An `external` instance method of a `@GoType` class | The Go method name, e.g. `'DrawText'`; invoked on the receiver. |
| `@GoName(name)` | An `external` top-level getter, or an `external static` getter of a `@GoType` class | A Go constant or package-level variable, fully qualified, e.g. `'wio.Red'`; emitted as a bare identifier (no call). |
| `@GoType(name)` | A class | The Go type behind values of this class, e.g. `'*wio.Display'`. The transpiler never constructs these itself; only `@GoName` functions produce them. |

A declaration must satisfy all three (be `external`, carry `@GoName`, and live in a library with `@GoImport`) before the checker accepts a call to it. Missing pieces are reported with file/line, pointing at the annotation that's absent.

```dart
@GoImport('github.com/o-ga09/dart2tinygo/packages/wio_terminal/go', alias: 'wio')
library;

import 'package:tinygo_annotations/tinygo_annotations.dart';

@GoName('wio.NewDisplay')
external Display newDisplay();

@GoType('*wio.Display')
class Display {
  Display._();

  @GoName('Clear')
  external void clear();

  @GoName('DrawText')
  external void drawText(int x, int y, String text, Color color);

  @GoName('Width')
  external int width();
}

/// A value type: no `*`, passed by value.
@GoType('wio.Color')
class Color {
  Color._();

  @GoName('wio.Red')
  external static Color get red;
}

@GoName('wio.RGB')
external Color rgb(int r, int g, int b);
```

```go
package wio

type Display struct{ /* ... */ }
type Color uint16

var Red = Color(0xF800)

func NewDisplay() *Display                                  { /* ... */ }
func RGB(r, g, b int) Color                                 { /* ... */ }
func (d *Display) Clear()                                   { /* ... */ }
func (d *Display) DrawText(x, y int, text string, c Color)  { /* ... */ }
func (d *Display) Width() int                               { /* ... */ }
```

## What the transpiler currently supports calling

- Top-level binding functions and binding methods on a local that holds a `@GoType` value (`display.drawText(...)`), as a statement (a non-void result is discarded), as the initializer of a local, as an argument to another binding call, or inside `print(...)`. Chaining on a call result (`newDisplay().clear()`) is not supported yet.
- Result and local types: `int`, `double`, `bool`, `String`, and `@GoType` classes. A `@GoType` may name a value type (`'wio.Color'`) or a pointer (`'*wio.Display'`); the string is emitted verbatim, so both work.
- Arguments: literals of those types, locals, other binding calls, and Go constant references (`red`, `Color.red`). Dart `int` / `double` / `bool` / `String` parameters correspond to Go `int` / `float64` / `bool` / `string`; declare the Go signature with those types (a Go side that wants `uint8` converts inside the binding — the transpiler emits no casts).
- Go constants and package-level variables: `@GoName` on an `external` top-level getter or an `external static` getter. Instance getters are not bindings; expose a Go method that returns a value as an `external` method.

See [`mapping.md`](./mapping.md) for the generated Go.

## Decided, not yet implemented (2026-09-22)

- **No new annotations for Go multi-value returns, `error`, pointers vs.
  values, or struct construction.** The Go half of the binding is the
  adapter: it wraps such APIs into single-value functions and methods
  (errors become `panic` or a `bool` result), exactly as `wio.NewDisplay`
  folds the ILI9341/SPI setup. `@GoType` names the exact Go type expression,
  `*` included.
- **Enums:** a Dart `enum` may carry `@GoType('machine.Pin')` with
  `@GoName('machine.D0')` on each value.
- **Chaining and cascades** on binding results (`newDisplay().clear()`,
  `newDisplay()..clear()..drawText(...)`).
- The `tinygo_machine` binding starts with `Pin.led` / `Pin(n)` /
  `configure(PinMode.output | PinMode.input)` / `high()` / `low()` /
  `toggle()` / `get()`; `machine.LED` and `machine.PinConfig{...}` are
  absorbed by its Go half per the first rule.

## Shipping the Go runtime with the binding

Put the Go module in a `go/` directory next to the binding's `pubspec.yaml` (module path = repository path of that directory, e.g. `github.com/o-ga09/dart2tinygo/packages/wio_terminal/go`). When the transpiler sees a binding whose package has `go/go.mod`, it emits

```
require <module> v0.0.0
replace <module> => /absolute/path/to/go
```

into the generated `go.mod` and runs `go mod tidy`, so examples build from a checkout without publishing the module. Bindings without an in-tree `go/` are resolved by `go mod tidy` like any other dependency.

Keep the Dart declarations and the Go signatures in sync by hand; the transpiler does not cross-check them, so a mismatch shows up as a `tinygo build` error.

## Reference bindings in this repository

- `packages/wio_terminal`: Seeed Wio Terminal (LCD text). Used by `examples/hello_wioterminal`.
- `packages/tinygo_machine`: planned board-agnostic bindings for TinyGo's `machine` package (not implemented yet).
