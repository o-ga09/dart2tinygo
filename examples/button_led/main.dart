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
