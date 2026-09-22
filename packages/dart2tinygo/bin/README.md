**Languages:** English | [日本語](./README.ja.md)

CLI entry point (`dart2tinygo.dart`). `build`, `check`, and `flash` are implemented for the v0.0.2 subset (see [`docs/supported_features.md`](../../../docs/supported_features.md)). `flash` runs `build`, then `tinygo flash -target=<target> [-port=<port>]` in the output directory with stdio inherited; it requires `tinygo` on `PATH` and real hardware to actually flash.
