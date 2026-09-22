# tinygo_machine (package)

**Languages:** English | [日本語](./README.ja.md)

Board-agnostic bindings corresponding to TinyGo's `machine` package (GPIO, ADC, LED).

Following the design principle of not putting board-specific code into the core (`packages/dart2tinygo`), this package only deals with functionality that TinyGo provides in common. Board-specific bindings live in separate packages (e.g. `package:wio_terminal`).

```dart
import 'dart:io';

import 'package:tinygo_machine/tinygo_machine.dart';

void main() {
  final led = Pin.led..configure(PinMode.output);
  while (true) {
    led.toggle();
    sleep(const Duration(milliseconds: 500));
  }
}
```

- **GPIO**: `Pin.led` (the board's own user LED), `Pin(n)` (an arbitrary pin
  number), `configure(PinMode.output | PinMode.input)` (input uses an
  internal pull-up), `high()`/`low()`/`toggle()`/`get()`.
- **ADC**: `newAdc(pin)` configures a `Pin` as an analog input; `.read()`
  returns the raw 0-65535 sample.
- **PWM** is not implemented yet — every chip family TinyGo supports exposes
  a different PWM peripheral type with no common shape (unlike GPIO/ADC), so
  a board-agnostic API needs real per-chip-family work; see
  [`docs/writing_bindings.md`](../../docs/writing_bindings.md#decided-not-yet-implemented-2026-09-22).

See `examples/blinky` for a full board-agnostic example, buildable for any
TinyGo target (`tinygo build -target=<board> .`).
