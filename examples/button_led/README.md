**Languages:** English | [日本語](./README.ja.md)

# button_led

Lights the Wio Terminal's user LED (blue) while button A is held down.

```dart
import 'package:wio_terminal/wio_terminal.dart';

void main() {
  final led = newLed();
  final buttons = newButtons();
  while (true) {
    if (buttons.isPressed(Button.a)) {
      led.on();
    } else {
      led.off();
    }
  }
}
```

## Requirements

- Dart SDK 3.x
- Go and [TinyGo](https://tinygo.org/getting-started/install/) (tested with TinyGo 0.42.0)
- A Wio Terminal connected over USB

## Run

```sh
# 1. Resolve dependencies (once, at the repository root — it is a pub workspace)
dart pub get
dart pub global activate dart2tinygo   # once, installs the `dart2tinygo` CLI

# 2. Convert to Go (writes main.go and go.mod, runs `go mod tidy`) and flash
dart2tinygo flash examples/button_led/main.dart \
  -o examples/button_led/build --target=wioterminal
```

Holding button A (top-left of the three top buttons) lights the LED; letting
go turns it off.

See [`packages/wio_terminal`](../../packages/wio_terminal) for the
`newLed()` / `newButtons()` bindings used here.
