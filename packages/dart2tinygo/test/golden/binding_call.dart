import 'dart:io';

import 'package:test_binding/test_binding.dart';

void main() {
  final widget = newWidget();
  var count = 0;
  widget.show(10, 20, 'hello');
  beep(3);
  while (true) {
    count++;
    widget.show(10, 20, 'tick');
    beep(count);
    widget.hide();
    sleep(const Duration(milliseconds: 250));
  }
}
