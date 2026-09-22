class Rect {
  int width;
  int height;

  Rect(this.width, this.height) {
    if (width < 0) {
      width = 0;
    }
  }

  int area() => width * height;

  void grow() {
    width++;
    bumpHeight();
  }

  void bumpHeight() {
    height += 1;
  }
}

void main() {
  final r = Rect(3, 4);
  print('${r.area()}');
  r.grow();
  print('${r.width} ${r.height}');
}
