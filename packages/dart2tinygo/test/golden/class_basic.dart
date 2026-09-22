class Counter {
  int value;

  Counter(this.value);

  void inc() {
    value++;
  }

  int addTo(int value) => this.value + value;
}

void main() {
  final c = Counter(0);
  c.inc();
  c.inc();
  print('${c.value}');
  print('${c.addTo(3)}');
  c.value = 10;
  c.value += 5;
  var same = c == c;
  print('$same');
}
