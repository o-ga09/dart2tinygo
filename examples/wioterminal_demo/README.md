**Languages:** English | [日本語](./README.ja.md)

# wioterminal_demo

A single menu-driven program that exercises every Wio Terminal binding in
this repository, doubling as the FlutterKaigi booth demo and as an
integration test that surfaces missing binding APIs. Navigate with the
5-way switch (up/down), confirm with button A; button C leaves a running
feature and returns to the menu.

| Menu item | Feature |
| --- | --- |
| Blink LED | User LED (#13) |
| Play melody | Buzzer / PWM tone (#15) |
| Light/mic levels | Ambient light + microphone ADC as bar graphs (#16) |
| Spirit level | Accelerometer tilt, drawn as a dot on the LCD (#17) |
| Send IR code | IR transmit, a NEC frame (#18) |
| SD card log | microSD (FAT) append (#19) |
| Wi-Fi HTTP GET | RTL8720DN Wi-Fi + HTTP GET (#20) — edit the placeholder SSID/password in `main.dart` first; with the placeholders it simply reports a connect failure |

```dart
import 'dart:io';

import 'package:wio_terminal/wio_terminal.dart';
import 'package:wio_terminal/sd.dart';
import 'package:wio_terminal/wifi.dart';

void main() {
  final display = newDisplay();
  final led = newLed();
  final buttons = newButtons();
  // ... one handle per binding ...

  var selected = 0;
  drawMenu(display, selected);

  while (true) {
    if (buttons.isPressed(Button.down)) {
      selected += 1;
      selected %= 7;
      drawMenu(display, selected);
      sleep(const Duration(milliseconds: 200));
    } else if (buttons.isPressed(Button.a)) {
      switch (selected) {
        case 0:
          runBlink(display, led, buttons);
        // ... one case per menu item ...
      }
      drawMenu(display, selected);
    }
  }
}
```

See [`main.dart`](./main.dart) for the full program.

## Requirements

- Dart SDK 3.x
- Go and [TinyGo](https://tinygo.org/getting-started/install/) (tested with TinyGo 0.42.0)
- A Wio Terminal connected over USB
- Optional: a microSD card (SD card log item) and a Wi-Fi access point (Wi-Fi item)

## Run

`dart2tinygo flash` doesn't take extra `tinygo` flags yet, and the Wi-Fi/HTTP
binding used by the last menu item needs a larger goroutine stack than
TinyGo's default (see `packages/wio_terminal/lib/wifi.dart`), so build and
flash in two steps with `-stack-size=4KB` on the second one:

```sh
# 1. Resolve dependencies (once, at the repository root — it is a pub workspace)
dart pub get
dart pub global activate dart2tinygo   # once, installs the `dart2tinygo` CLI

# 2. Convert to Go (writes main.go and go.mod, runs `go mod tidy`)
dart2tinygo build examples/wioterminal_demo/main.dart \
  -o examples/wioterminal_demo/build

# 3. Build and flash with TinyGo directly
cd examples/wioterminal_demo/build
tinygo flash -target=wioterminal -stack-size=4KB .
```

## Known limitation

`mountSdCard()` (used by the "SD card log" item) panics if no card is
inserted — the binding has no way to surface a Go error from a constructor
yet (#19). The demo gives you a chance to back out with button C before it
mounts, but if you do press A without a card inserted, the whole program
halts and needs a reset.

See [`packages/wio_terminal`](../../packages/wio_terminal) for every
binding used here.
