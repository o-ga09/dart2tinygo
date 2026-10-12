void main() {
  int flags = 0x0F;
  int mask = flags & 0x03;
  int shifted = flags << 2;
  int signedByte = (mask | 0x80).toSigned(8);
  print('$signedByte');

  var a = flags | mask ^ 1;
  var b = flags & mask + 1;
  var c = ~flags >> 1;
  var d = (flags | 1) == 0x0F;
  flags &= 0x0E;
  flags |= 1;
  flags ^= 2;
  flags <<= 1;
  flags >>= 1;
  print('$a $b $c $d $shifted $flags');
}
