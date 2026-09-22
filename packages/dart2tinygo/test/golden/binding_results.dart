import 'package:test_binding/test_binding.dart';

void main() {
  final widget = newWidget();
  final level = readLevel();
  final ready = isReady();
  var volts = voltage();
  var name = label();
  final color = rgb(255, 0, 0);
  final button = Button.a;
  double gain = 2;
  bool on = false;
  String title = 'main';
  widget.fill(color);
  widget.fill(red);
  widget.fill(rgb(0, 255, 0));
  widget.configure(ready, gain, name);
  widget.configure(on, volts, title);
  widget.configure(true, 0.5, 'x');
  final pressed = widget.press(button);
  final other = widget.press(Button.b);
  final x = widget.level();
  print(name);
  print(label());
  print('level $level ready $ready name $name');
  print('x $x other $other pressed $pressed');
  print('live ${widget.level()} ${isReady()} ${label()}');
}
