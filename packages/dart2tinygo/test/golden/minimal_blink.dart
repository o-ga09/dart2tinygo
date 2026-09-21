import 'dart:io';

void main() {
  var count = 0;
  while (true) {
    count++;
    print('blink $count');
    sleep(const Duration(milliseconds: 500));
  }
}
