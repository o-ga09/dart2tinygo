//go:build atsamd51 && !atsamd51g19

package tgm

import "machine"

// pwmCandidates lists every TCC peripheral this atsamd51 variant exposes.
// atsamd51g19 only has three (TCC0-2); see pwm_atsamd51g19.go.
func pwmCandidates() []pwmPeripheral {
	return []pwmPeripheral{machine.TCC0, machine.TCC1, machine.TCC2, machine.TCC3, machine.TCC4}
}
