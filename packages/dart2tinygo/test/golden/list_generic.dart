void main() {
  var temps = <double>[1.5, 2.5];
  temps.add(3.5);
  temps[0] = 9.0;
  var t = temps[0];
  var n = temps.length;

  var flags = [true, false];
  flags.add(true);
  var f = flags[1];

  var names = <String>['a', 'b'];
  names.add('c');
  names[0] = 'z';
  var first = names[0];
  var count = names.length;

  var empty = <String>[];
  empty.add('x');

  print('t=$t n=$n f=$f first=$first count=$count e=${empty.length}');
}
