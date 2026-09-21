import 'dart:io';

import 'package:wio_terminal/wio_terminal.dart';

void main() {
  final display = newDisplay();
  display.drawText(40, 120, 'Hello From Dart !');
  while (true) {
    sleep(const Duration(seconds: 1));
  }
}
