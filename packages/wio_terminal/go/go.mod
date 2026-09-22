module github.com/o-ga09/dart2tinygo/packages/wio_terminal/go

go 1.27

require (
	github.com/o-ga09/dart2tinygo/packages/tinygo_machine/go v0.0.0
	tinygo.org/x/drivers v0.33.0
	tinygo.org/x/tinydraw v0.4.0
	tinygo.org/x/tinyfont v0.6.0
	tinygo.org/x/tinyfs v0.5.0
)

require github.com/google/shlex v0.0.0-20191202100458-e7afc7fbc510 // indirect

replace github.com/o-ga09/dart2tinygo/packages/tinygo_machine/go => ../../tinygo_machine/go
