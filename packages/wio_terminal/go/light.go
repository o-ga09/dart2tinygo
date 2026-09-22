package wio

import "machine"

// LightSensor is the Wio Terminal's built-in ambient light sensor
// (machine.WIO_LIGHT = PD01, ADC).
type LightSensor struct {
	adc machine.ADC
}

// NewLightSensor configures the light sensor pin as an analog input.
func NewLightSensor() *LightSensor {
	machine.InitADC()
	adc := machine.ADC{Pin: machine.WIO_LIGHT}
	adc.Configure(machine.ADCConfig{})
	return &LightSensor{adc: adc}
}

// Read returns the raw sample (0-65535, like TinyGo's own machine.ADC.Get).
func (l *LightSensor) Read() int {
	return int(l.adc.Get())
}

// ReadPercent normalizes the raw sample to 0-100.
func (l *LightSensor) ReadPercent() int {
	return l.Read() * 100 / 65535
}
