import 'package:test_binding/test_binding.dart';

void main() {
  final widget = newWidget();
  final data = widget.readBytes('/config.txt');
  final text = String.fromCharCodes(data);
  widget.writeBytes('/log.txt', 'hello'.codeUnits);
  print('read ${data.length} bytes: $text');
}
