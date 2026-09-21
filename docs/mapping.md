# Dart → Go conversion rules

**Languages:** English | [日本語](./mapping.ja.md)

Record conversion rules here once they're decided.

## v0.1 minimal transpile (decided, implemented)

Scope: a single top-level `void main()` with `int` locals, `while (true)`,
`print(...)`, and `sleep(Duration(...))` — see `HANDOFF_dart2tinygo.md` §7
task 2. Implemented in `packages/dart2tinygo/lib/src/backend/generator.dart`.

| Dart | Go |
| --- | --- |
| `void main() { ... }` | `func main() { ... }` |
| `var x = <int literal>;` | `x := <int literal>` |
| `while (true) { ... }` | `for { ... }` |
| `x++` / `x--` | `x++` / `x--` |
| `print(<string>)` | `println(<string>)` — not `fmt.Println`, to avoid pulling in `fmt` on TinyGo |
| `print('... $x ...')` | string concatenation: `"... " + strconv.Itoa(x) + " ..."` |
| `sleep(Duration(milliseconds: n))` | `time.Sleep(n * time.Millisecond)` (also supports `seconds`/`minutes`/`hours`/`days`/`microseconds`, summed when combined) |

Go imports (`strconv`, `time`) are only emitted when the generated code
actually uses them.

## Annotation bindings (decided, implemented)

Calls into `@GoName` declarations (see [`writing_bindings.md`](./writing_bindings.md))
map 1:1 onto Go calls; the transpiler adds no wrapper code of its own.

| Dart | Go |
| --- | --- |
| `@GoImport('pkg/path', alias: 'p')` on the binding library | `import p "pkg/path"` (only when a binding from that library is used; without `alias`, `import "pkg/path"`) |
| `final d = newDisplay();` where `newDisplay` is `@GoName('wio.NewDisplay')` | `d := wio.NewDisplay()` (`final`/`var` make no difference; Go infers the `@GoType`) |
| `beep(3);` where `beep` is `@GoName('rt.Beep')` | `rt.Beep(3)` |
| `d.drawText(10, 20, 'hi');` where `drawText` is `@GoName('DrawText')` | `d.DrawText(10, 20, "hi")` |
| Arguments: `int` literal / `String` literal / `int` local | Emitted verbatim: untyped constant / Go string literal / identifier |

Generated `go.mod`: for each binding whose Dart package ships `go/go.mod`,
`require <module> v0.0.0` plus `replace <module> => <absolute local path>`,
followed by `go mod tidy`. Everything else is left to `go mod tidy`.

## Numeric semantics (to be decided)

- Dart's `int` is assumed to be 64-bit. Whether the Go side uses `int64` or `int` is undecided.
- Note that Go's `int` becomes 32-bit on 32-bit MCUs (needs consideration).
- Since dart2js (Flutter Web) makes bitwise operations 32-bit, users who share code with Flutter will need a warning in the README (not yet started).
- The v0.1 minimal transpile above only emits `int` literals as Go untyped constants (`x := 0`), so this question doesn't bite yet; it must be resolved before wider `int` support lands.

## Type mapping table (undefined beyond the v0.1 minimal subset above)

| Dart | Go |
| --- | --- |
| (TBD) | (TBD) |

## String interpolation (implemented for `int`, policy for the rest)

- Do not use `fmt.Sprintf`. Concatenate with `strconv` etc. based on type, to avoid bloating the TinyGo binary.
- Implemented: `int`-typed interpolation expressions via `strconv.Itoa`.
- Not yet implemented: `double` / `bool` / `String` / arbitrary expressions in interpolation.
