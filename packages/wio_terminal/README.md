# wio_terminal (package)

**Languages:** English | [日本語](./README.ja.md)

[![pub package](https://img.shields.io/pub/v/wio_terminal.svg)](https://pub.dev/packages/wio_terminal)

dart2tinygo binding for the [Seeed Wio Terminal](https://wiki.seeedstudio.com/Wio-Terminal-Getting-Started/).
The Dart side (`lib/wio_terminal.dart`) is annotations only; the behaviour is
the TinyGo package in `go/` (`github.com/o-ga09/dart2tinygo/packages/wio_terminal/go`, imported as `wio`).

Currently provided:

| Dart | Go | Purpose |
| --- | --- | --- |
| `newDisplay()` | `wio.NewDisplay()` | Configure SPI3 + the ILI9341 LCD (landscape, backlight on, cleared to black) |
| `Display.clear()` | `(*Display).Clear()` | Fill the screen with black |
| `Display.drawText(x, y, text)` | `(*Display).DrawText(x, y, text)` | Draw white text (FreeMono Bold 12pt) with its baseline at (x, y) |
| `newLed()` | `wio.NewLed()` | Configure the user LED (blue, `machine.LED`) as an output |
| `Led.on()` / `.off()` / `.toggle()` | `(*Led).On()` / `.Off()` / `.Toggle()` | Drive the user LED |
| `newButtons()` | `wio.NewButtons()` | Configure buttons A/B/C and the 5-way switch as pull-up inputs |
| `Buttons.isPressed(button)` / `.waitPressed(button)` | `(*Buttons).IsPressed(button)` / `.WaitPressed(button)` | Poll or block (debounced) on a [`Button`](./lib/wio_terminal.dart) |

See `examples/hello_wioterminal` for usage and [docs/writing_bindings.md](../../docs/writing_bindings.md) for how the annotations work.

This package lives in the main repository for now so the example builds from a
checkout; the design still treats board bindings as separable packages, and it
may move to its own repository later.
