import 'dart:io';

import 'package:test_binding/test_binding.dart';

void main() {
  final widget = newWidget();
  for (var y = 0; y < 240; y += 20) {
    widget.show(0, y, 'line');
  }

  var count = 0;
  while (count < 10) {
    count++;
  }

  var sum = 0;
  for (var i = 0; i < 5; i++) {
    if (i == 3) {
      break;
    }
    if (i == 1) {
      continue;
    }
    sum += i;
  }

  var scale = 1.0;
  while (scale < 2.0) {
    scale *= 1.1;
  }

  print('count=$count sum=$sum');
  beep(count);
  sleep(const Duration(milliseconds: 10));
}
