package wio

import (
	"machine"
	"time"
)

// buzzerTCC is the TCC peripheral wired to machine.WIO_BUZZER (PD11): per
// the atsamd51 pin/timer mapping table, PD11 (PD10's odd sibling) is
// TCC0/WO[4], confirmed against the installed TinyGo 0.42 source.
var buzzerTCC = machine.TCC0

// Buzzer is the Wio Terminal's built-in buzzer (machine.WIO_BUZZER = PD11).
type Buzzer struct {
	channel uint8
}

// NewBuzzer configures the buzzer pin for PWM output, silent until Tone or
// Beep is called.
func NewBuzzer() *Buzzer {
	buzzerTCC.Configure(machine.PWMConfig{Period: 500000}) // 2kHz default
	channel, err := buzzerTCC.Channel(machine.WIO_BUZZER)
	if err != nil {
		panic("wio: buzzer PWM channel unavailable: " + err.Error())
	}
	b := &Buzzer{channel: channel}
	b.Stop()
	return b
}

// Tone starts (or retunes) a continuous tone at freqHz, at a 50% duty
// cycle. Keeps sounding until Stop is called.
func (b *Buzzer) Tone(freqHz int) {
	if freqHz > 0 {
		buzzerTCC.SetPeriod(uint64(1e9) / uint64(freqHz))
	}
	buzzerTCC.Set(b.channel, buzzerTCC.Top()/2)
}

// Stop silences the buzzer.
func (b *Buzzer) Stop() {
	buzzerTCC.Set(b.channel, 0)
}

// Beep sounds freqHz for durationMs milliseconds, then stops.
func (b *Buzzer) Beep(freqHz, durationMs int) {
	b.Tone(freqHz)
	time.Sleep(time.Duration(durationMs) * time.Millisecond)
	b.Stop()
}
