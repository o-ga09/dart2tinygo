package wio

import (
	"tinygo.org/x/tinydraw"
	"tinygo.org/x/tinyfont"
	"tinygo.org/x/tinyfont/freemono"
)

// DrawPixel sets a single pixel to c.
func (d *Display) DrawPixel(x, y int, c Color) {
	d.dev.SetPixel(int16(x), int16(y), c.rgba())
}

// DrawLine draws a straight line from (x0, y0) to (x1, y1) in c.
func (d *Display) DrawLine(x0, y0, x1, y1 int, c Color) {
	tinydraw.Line(d.dev, int16(x0), int16(y0), int16(x1), int16(y1), c.rgba())
}

// DrawRect draws the outline of a w x h rectangle with its top-left corner
// at (x, y), in c. Coordinates outside the screen are silently ignored (the
// annotation machinery has no way to surface the underlying Go error).
func (d *Display) DrawRect(x, y, w, h int, c Color) {
	d.dev.DrawRectangle(int16(x), int16(y), int16(w), int16(h), c.rgba())
}

// FillRect fills a w x h rectangle with its top-left corner at (x, y), in c.
func (d *Display) FillRect(x, y, w, h int, c Color) {
	d.dev.FillRectangle(int16(x), int16(y), int16(w), int16(h), c.rgba())
}

// DrawCircle draws the outline of a circle centered at (x, y) with radius r,
// in c.
func (d *Display) DrawCircle(x, y, r int, c Color) {
	tinydraw.Circle(d.dev, int16(x), int16(y), int16(r), c.rgba())
}

// FillCircle draws a filled circle centered at (x, y) with radius r, in c.
func (d *Display) FillCircle(x, y, r int, c Color) {
	tinydraw.FilledCircle(d.dev, int16(x), int16(y), int16(r), c.rgba())
}

// DrawTextColor draws text in c (FreeMono Bold 12pt) with its baseline at
// (x, y).
func (d *Display) DrawTextColor(x, y int, text string, c Color) {
	tinyfont.WriteLine(d.dev, &freemono.Bold12pt7b, int16(x), int16(y), text, c.rgba())
}

// DrawTextSize draws text in c with its baseline at (x, y), at the given
// point size (9/12/18/24; any other value falls back to 12).
func (d *Display) DrawTextSize(x, y int, text string, c Color, size int) {
	tinyfont.WriteLine(d.dev, fontForSize(size), int16(x), int16(y), text, c.rgba())
}

// TextWidth returns the rendered width of text in pixels, at the given
// point size (9/12/18/24; any other value falls back to 12).
func (d *Display) TextWidth(text string, size int) int {
	_, outboxWidth := tinyfont.LineWidth(fontForSize(size), text)
	return int(outboxWidth)
}

func fontForSize(size int) tinyfont.Fonter {
	switch size {
	case 9:
		return &freemono.Bold9pt7b
	case 18:
		return &freemono.Bold18pt7b
	case 24:
		return &freemono.Bold24pt7b
	default:
		return &freemono.Bold12pt7b
	}
}
