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
  external void drawText(int x, int y, String text);
}
```

```go
package wio

type Display struct{ /* ... */ }

func NewDisplay() *Display                     { /* ... */ }
func (d *Display) Clear()                      { /* ... */ }
func (d *Display) DrawText(x, y int, text string) { /* ... */ }
```

## What the transpiler currently supports calling

- Top-level binding functions, as a statement or as the initializer of a local (`final display = newDisplay();`). A local may only hold a `@GoType` value or an `int`.
- Binding methods on a local that holds a `@GoType` value (`display.drawText(...)`). Chaining on a call result (`newDisplay().clear()`) is not supported yet.
- Arguments: `int` literals, `String` literals, and `int` locals. Dart `int` parameters correspond to Go `int` and `String` to `string`.

See [`mapping.md`](./mapping.md) for the generated Go.

## Decided, not yet implemented (2026-09-22)

- **No new annotations for Go multi-value returns, `error`, pointers vs.
  values, or struct construction.** The Go half of the binding is the
  adapter: it wraps such APIs into single-value functions and methods
  (errors become `panic` or a `bool` result), exactly as `wio.NewDisplay`
  folds the ILI9341/SPI setup. `@GoType` names the exact Go type expression,
  `*` included.
- **Constants:** `@GoName` on an `external` top-level getter or static
  getter maps to a bare Go identifier (no call), e.g.
  `@GoName('wio.Red') external Color get red;` → `wio.Red`.
- **Enums:** a Dart `enum` may carry `@GoType('machine.Pin')` with
  `@GoName('machine.D0')` on each value.
- **Chaining and cascades** on binding results (`newDisplay().clear()`,
  `newDisplay()..clear()..drawText(...)`).
- **`@GoType` values as arguments**, passed verbatim (locals or call results).
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
