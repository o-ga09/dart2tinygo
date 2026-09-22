void main() {
  var mode = 2;
  switch (mode) {
    case 0:
      print('off');
    case 1:
    case 2:
      print('on');
    default:
      print('?');
  }

  var name = 'b';
  switch (name) {
    case 'a':
      print('first');
    case 'b':
      print('second');
    default:
      print('other');
  }

  var flag = true;
  switch (flag) {
    case true:
      print('yes');
    case false:
      print('no');
  }
}
