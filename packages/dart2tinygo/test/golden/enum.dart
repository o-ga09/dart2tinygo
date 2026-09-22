enum Mode { off, on }

void main() {
  var m = Mode.on;
  print(m.name);
  print('${m.index}');
  switch (m) {
    case Mode.off:
      print('off');
    case Mode.on:
      print('on');
  }
  if (m == Mode.on) {
    print('is on');
  }
}
