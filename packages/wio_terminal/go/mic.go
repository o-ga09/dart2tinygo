package wio

import (
	"machine"
	"time"
)

// Microphone is the Wio Terminal's built-in microphone (machine.WIO_MIC =
// PC30, ADC).
type Microphone struct {
	adc machine.ADC
}

// NewMicrophone configures the microphone pin as an analog input.
func NewMicrophone() *Microphone {
	machine.InitADC()
	adc := machine.ADC{Pin: machine.WIO_MIC}
	adc.Configure(machine.ADCConfig{})
	return &Microphone{adc: adc}
}

// Read returns an instantaneous raw sample (0-65535).
func (m *Microphone) Read() int {
	return int(m.adc.Get())
}

// ReadLevel samples continuously for windowMs milliseconds and returns the
// peak-to-peak amplitude (0-65535), a simple loudness estimate.
func (m *Microphone) ReadLevel(windowMs int) int {
	deadline := time.Now().Add(time.Duration(windowMs) * time.Millisecond)
	min, max := uint16(0xFFFF), uint16(0)
	for time.Now().Before(deadline) {
		v := m.adc.Get()
		if v < min {
			min = v
		}
		if v > max {
			max = v
		}
	}
	return int(max - min)
}
