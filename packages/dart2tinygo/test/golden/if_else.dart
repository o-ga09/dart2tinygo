import 'dart:io';

import 'package:test_binding/test_binding.dart';

void main() {
  final widget = newWidget();
  final button = Button.a;
  var count = 0;
  var level = 2;
  double threshold = 1.5;
  bool ready = true;

  if (isReady()) {
    print('ready at boot');
  }

  while (true) {
    if (widget.press(button)) {
      count++;
      print('pressed $count');
    } else if (widget.press(Button.b)) {
      print('b pressed');
    } else {
      print('idle');
    }

    if (level > 0 && level <= 10) {
      print('in range');
    }

    if (!ready || level == 0) {
      print('not ready');
    }

    if (voltage() >= threshold) {
      print('ok');
    }

    if (level > 0) {
      if (level > 5) {
        print('big');
      } else {
        print('small');
      }
    }

    beep(level);
    sleep(const Duration(milliseconds: 50));
  }
}
