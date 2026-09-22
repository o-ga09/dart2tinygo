import 'dart:io';

import 'package:test_binding/test_binding.dart';

void main() {
  final widget = newWidget();
  final raw = readLevel();
  final scale = raw.toDouble() / 1024.0 * 3.3;
  final rounded = scale.round();
  final truncated = scale.toInt();
  var sum = scale + 0.5;
  var diff = scale - 0.5;
  var prod = scale * 2.0;
  var neg = -scale;

  var x = 1.0;
  x += 0.5;
  x -= 0.25;
  x *= 2.0;
  x /= 4.0;

  if (scale > 3.0) {
    print('scale=$scale over 3.0');
  }

  widget.configure(true, scale, 'volts');
  print(
      'scale=$scale sum=$sum diff=$diff prod=$prod neg=$neg rounded=$rounded truncated=$truncated x=$x volts=${voltage()}');
  sleep(const Duration(milliseconds: 50));
}
