import 'package:test_binding/test_binding.dart';

void pressTwice(Widget w, Button b) {
  w.press(b);
  w.press(b);
}

Button firstButton() => Button.a;

void main() {
  final widget = newWidget();
  pressTwice(widget, firstButton());
}
