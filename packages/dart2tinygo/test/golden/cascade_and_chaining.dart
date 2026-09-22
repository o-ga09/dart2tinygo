import 'package:test_binding/test_binding.dart';

void main() {
  newWidget()
    ..show(40, 120, 'Hello From Dart !')
    ..hide();

  final widget = newWidget()
    ..show(0, 0, 'ready')
    ..fill(red);

  var level = widget.level();
  beep(newWidget().level());
  print('level=$level chained=${newWidget().level()}');
}
