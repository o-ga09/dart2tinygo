void main() {
  var x = 3.7;
  var rounded = x.round();
  var truncated = x.toInt();
  var d = 5;
  var scaled = d.toDouble() / 2.0;
  print('rounded=$rounded truncated=$truncated scaled=$scaled x=$x');
}
