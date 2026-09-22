import 'dart:io';

import 'package:tinygo_machine/tinygo_machine.dart';

void main() {
  final led = Pin.led..configure(PinMode.output);
  var count = 0;
  while (true) {
    led.toggle();
    count++;
    print('blink $count');
    sleep(const Duration(milliseconds: 500));
  }
}
