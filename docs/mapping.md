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
| `final n = sensor.read();` / `var ok = isReady();` (`int` / `double` / `bool` / `String` / `@GoType` results) | `n := sensor.Read()` / `ok := rt.IsReady()` (Go infers the type; a non-void result used as a statement is discarded) |
| `red` / `Button.a` where the getter is `@GoName('rt.Red')` / `@GoName('rt.ButtonA')` | `rt.Red` / `rt.ButtonA` — a bare identifier, no call |
| Arguments: `int` / `double` / `bool` / `String` literal, local, binding call, Go constant reference | Emitted verbatim: untyped constant / identifier / call / identifier. No casts: a Go parameter must be `int` / `float64` / `bool` / `string` or the `@GoType` itself |

Generated `go.mod`: for each binding whose Dart package ships `go/go.mod`,
`require <module> v0.0.0` plus `replace <module> => <absolute local path>`,
followed by `go mod tidy`. Everything else is left to `go mod tidy`.

## Numeric semantics (decided 2026-09-22, not yet implemented beyond `int` literals)

- **`int` → Go `int`** (platform width: 32-bit on 32-bit MCUs such as the
  SAMD51, wrapping at 32 bits). Rationale: Dart already accepts
  platform-dependent integer semantics on the web (dart2js: 32-bit bitwise
  operations), bindings can then use Go's idiomatic `int` without conversions
  at every boundary, and 64-bit arithmetic is software-emulated on Cortex-M.
  The README must carry the same warning dart2js users know.
- **`double` → `float64`**. Correctness over size: Dart has no precedent for
  32-bit doubles, and silent precision loss is worse than a slower software
  double on FPUs that are single-precision only.
- Integer literals stay untyped Go constants (`x := 0`).
- `~/` → Go `/` (both truncate toward zero). `%` differs (Dart `-5 % 3 == 1`,
  Go `-2`) and goes through the runtime helper below.

## Type mapping table (decided 2026-09-22; "impl." marks what exists today)

| Dart | Go | Status |
| --- | --- | --- |
| `int` | `int` | impl. (literals/locals/binding results) |
| `double` | `float64`; `double d = 2;` → `d := 2.0` so Go doesn't infer `int` | impl. (literals/locals/binding results; no arithmetic or interpolation yet) |
| `bool` | `bool` | impl. (literals/locals/binding results; no operators or `if` yet) |
| `String` | `string`; `.length` → `utf8.RuneCountInString` (UTF-16 vs UTF-8 differ outside the BMP); no indexing in v0.1 | impl. (literals/locals/binding results; no operations yet) |
| `Duration` | `time.Duration`; non-literal `Duration(milliseconds: n)` → `time.Duration(n) * time.Millisecond` | impl. (literals) |
| `List<T>` | `[]T`; `add` → `append`, `length` → `len`, indexing verbatim, `List.filled` → `make` + loop; growable/fixed not distinguished | decided (v0.2) |
| `enum` | `type E int` + `const ( ... iota )`; `.index` is the value, `.name` via a string table | decided (v0.2) |
| class (no inheritance) | `struct` + `NewFoo(...)` + pointer-receiver methods; instances are always `*Foo` (Dart reference semantics, `==` is identity) | decided (v0.2) |
| top-level function | `func`; positional parameters only, named/optional parameters rejected by the checker | decided |
| `if` / `while` / `for (;;)` / `for-in` / `switch` / `break` / `continue` | direct; `for-in` → `range`; Dart `switch` does not fall through, so neither does the output | decided |
| cascade `a..b()..c()` | temporary + statement sequence | decided |
| `@GoType` class | the annotated Go type expression, verbatim | impl. |
| inheritance, mixins, generics, `T?`, `throw`/exceptions, `async` | rejected by the checker | decided (future) |

## Common Go runtime (`dartrt`, decided 2026-09-22, not yet implemented)

Semantics that cannot be expressed as an inline Go expression go through a
small board-agnostic Go module at `packages/dart2tinygo/go/` (module
`github.com/o-ga09/dart2tinygo/packages/dart2tinygo/go`, imported as
`dartrt`), shipped and wired up exactly like a binding's `go/` (see
[`writing_bindings.md`](./writing_bindings.md)). It is imported only when
used. Initial contents: `FormatDouble` (Dart prints `1.0`, Go's
`strconv.FormatFloat` prints `1`), `Mod` (Dart `%`). This is language
semantics, not board knowledge, so it does not violate the core's
no-board-code rule.

## String interpolation (implemented for `int` / `bool` / `String`, decided for `double`)

- Do not use `fmt.Sprintf`. Concatenate with `strconv` etc. based on type, to avoid bloating the TinyGo binary.
- Implemented: `int` → `strconv.Itoa`, `bool` → `strconv.FormatBool`, `String` → verbatim. The interpolated expression may be any supported value expression (literal, local, binding call, Go constant), not only a local. `print(s)` likewise takes any `String` expression.
- Decided: `double` → `dartrt.FormatDouble` (waits for the `dartrt` runtime).

## Generated `go.mod`

- `go 1.25` (TinyGo 0.42's minimum); `go mod tidy` may raise it.
- One `require` + `replace` pair per in-tree Go runtime (bindings, `dartrt`).
