**Languages:** English | [日本語](./README.ja.md)

Directory for golden tests. Holds pairs of `<case>.dart` input and `<case>.go` expected output, run by `../golden_test.dart`. Regenerate with `UPDATE_GOLDENS=1 dart test test/golden_test.dart` (see [`CONTRIBUTING.md`](../../../../CONTRIBUTING.md)).

- `minimal_blink.dart` / `.go`: the v0.1 minimal subset (`void main()` + `int` locals + `while (true)` + `print` + `sleep`).
