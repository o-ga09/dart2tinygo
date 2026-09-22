void main() {
  var data = <int>[1, 2, 3];
  data.add(4);
  data[0] = 42;
  var first = data[0];
  var n = data.length;

  var s = 'hello world';
  var greeting = s.substring(0, 5);
  var rest = s.substring(6);
  var combined = greeting + rest;
  var codes = s.codeUnits;
  var text = String.fromCharCodes(codes);
  var textLen = text.length;

  print(
      'first=$first n=$n greeting=$greeting rest=$rest combined=$combined text=$text textLen=$textLen');
}
