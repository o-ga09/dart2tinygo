package dartrt

import "testing"

func TestMod(t *testing.T) {
	cases := []struct{ a, b, want int }{
		{-5, 3, 1},
		{5, 3, 2},
		{5, -3, 2},
		{-5, -3, 1},
		{0, 3, 0},
		{6, 3, 0},
	}
	for _, c := range cases {
		if got := Mod(c.a, c.b); got != c.want {
			t.Errorf("Mod(%d, %d) = %d, want %d", c.a, c.b, got, c.want)
		}
	}
}

func TestFormatDouble(t *testing.T) {
	cases := []struct {
		f    float64
		want string
	}{
		{1.0, "1.0"},
		{1.5, "1.5"},
		{-2.0, "-2.0"},
		{0.1, "0.1"},
	}
	for _, c := range cases {
		if got := FormatDouble(c.f); got != c.want {
			t.Errorf("FormatDouble(%v) = %q, want %q", c.f, got, c.want)
		}
	}
}
