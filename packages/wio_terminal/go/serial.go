package wio

import "machine"

// SerialAvailable returns the number of bytes currently buffered on the USB
// CDC serial connection (machine.Serial), ready to read.
func SerialAvailable() int {
	return machine.Serial.Buffered()
}

// SerialReadLine blocks until a newline ('\n') is read from the USB CDC
// serial connection, and returns the line without the trailing newline (or
// a trailing carriage return, if present).
func SerialReadLine() string {
	var line []byte
	for {
		b, err := machine.Serial.ReadByte()
		if err != nil {
			continue
		}
		if b == '\n' {
			break
		}
		line = append(line, b)
	}
	if n := len(line); n > 0 && line[n-1] == '\r' {
		line = line[:n-1]
	}
	return string(line)
}
