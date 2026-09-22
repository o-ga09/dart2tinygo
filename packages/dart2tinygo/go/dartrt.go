// Package dartrt provides the pieces of Dart's runtime numeric semantics
// that don't translate to a single Go expression (see docs/mapping.md,
// "Common Go runtime"). It is board-agnostic language semantics, not board
// knowledge, so it lives in the core, not a binding package. Generated code
// imports it only when it actually needs `%` or a `double` in a string;
// hand-written Go never imports it directly.
package dartrt

import "strconv"

// Mod implements Dart's `%` operator on int, which (unlike Go's `%`) always
// returns a non-negative result when possible: Dart's int.operator% is
// `remainder`, adjusted by `b` (or `-b`) whenever that remainder comes out
// negative. `-5 % 3` is `1` in Dart, `-2` in Go; `5 % -3` is `2` in both.
func Mod(a, b int) int {
	m := a % b
	if m < 0 {
		if b < 0 {
			m -= b
		} else {
			m += b
		}
	}
	return m
}

// FormatDouble formats f the way Dart's double.toString() does. Go's
// strconv.FormatFloat(f, 'f', -1, 64) prints "1" for a whole number; Dart
// prints "1.0". NaN/Infinity formatting is not handled specially yet (out
// of v0.1 minimal scope — sensor readings are always finite).
func FormatDouble(f float64) string {
	s := strconv.FormatFloat(f, 'f', -1, 64)
	for i := 0; i < len(s); i++ {
		if s[i] == '.' {
			return s
		}
	}
	return s + ".0"
}
