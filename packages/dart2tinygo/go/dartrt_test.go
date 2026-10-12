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

func TestToSigned(t *testing.T) {
	cases := []struct{ v, width, want int }{
		{0xFF, 8, -1},
		{0x7F, 8, 127},
		{0x80, 8, -128},
		{0x1FF, 8, -1},
		{0x8000, 16, -32768},
		{5, 8, 5},
		{1, 1, -1},
		{0, 1, 0},
		{-1, 64, -1},
		{1 << 62, 64, 1 << 62},
	}
	for _, c := range cases {
		if got := ToSigned(c.v, c.width); got != c.want {
			t.Errorf("ToSigned(%d, %d) = %d, want %d", c.v, c.width, got, c.want)
		}
	}
}
