# tinygo_machine (package)

**Languages:** English | [日本語](./README.ja.md)

[![pub package](https://img.shields.io/pub/v/tinygo_machine.svg)](https://pub.dev/packages/tinygo_machine)

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
- **PWM**: `newPwm(pin, freqHz)` probes every PWM peripheral this chip family
  exposes (TCC0-4 on atsamd51, PWM0-7 on rp2, ...) for one that can claim the
  pin — every chip family exposes a different peripheral type with no common
  shape, unlike GPIO/ADC, so this is real per-chip-family probing rather than
  a fixed mapping; `.setFrequency(freqHz)` retunes it (shared by every
  channel on the same underlying peripheral) and `.setDuty(percent)` sets
  the duty cycle (0-100).

See `examples/blinky` for a full board-agnostic example, buildable for any
TinyGo target (`tinygo build -target=<board> .`).
