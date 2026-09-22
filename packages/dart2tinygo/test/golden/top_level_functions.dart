int square(int x) => x * x;

void blink(int times) {
  var i = 0;
  while (i < times) {
    print('blink ${square(i)}');
    i++;
  }
}

int fib(int n) {
  if (n < 2) {
    return n;
  }
  return fib(n - 1) + fib(n - 2);
}

void log(String s) => print(s);

void main() {
  blink(3);
  var result = fib(6);
  print('fib(6)=$result');
  log('done');
}
