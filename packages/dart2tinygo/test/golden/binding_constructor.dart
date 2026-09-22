import 'package:test_binding/test_binding.dart';

void main() {
  final gpio = Gpio(3);
  beep(gpio.value());
  beep(Gpio(1 + 2).value());
}
