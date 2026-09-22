void main() {
  var a = -5;
  var b = a % 3;
  var c = a ~/ 3;
  var sum = a + b;
  var diff = a - b;
  var prod = a * (b + 1);
  var neg = -a;

  var i = 10;
  i += 1;
  i -= 2;
  i *= 3;
  i ~/= 2;
  i %= 4;

  for (var j = 0; j < 5; j += 2) {
    print('$j');
  }

  print('$sum $diff $prod $neg $c $i');
}
