//go:build atsamd51g19

package tgm

import "machine"

func pwmCandidates() []pwmPeripheral {
	return []pwmPeripheral{machine.TCC0, machine.TCC1, machine.TCC2}
}
