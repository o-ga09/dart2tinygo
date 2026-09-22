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
| `while (true) { ... }` | `for { ... }` (a general `while (cond)` becomes `for cond { ... }`) |
| `for (var i = <init>; cond; updater) { ... }` | `for i := <init>; cond; updater { ... }` — direct; exactly one declared loop variable, one condition, one updater (Go's post-clause is a single statement) |
| `break` / `continue` | `break` / `continue` — unlabeled only |
| `x++` / `x--` | `x++` / `x--` (int only) |
| `x += y` / `x -= y` / `x *= y` | same tokens in Go; `x`/`y` must have the same type, `int` or `double` |
| `a + b` / `a - b` / `a * b` | same tokens in Go; `x`/`y` must have the same type, `int` or `double` (not mixed) |
| `a ~/ b` | `a / b` — Go's `int` division already truncates toward zero, like Dart's `~/`; `int` only |
| `a % b` | `dartrt.Mod(a, b)` — Dart's `%` is never negative (`-5 % 3 == 1`); Go's `%` keeps the dividend's sign (`-5 % 3 == -2`), so a plain `%` would be wrong for negative operands; `int` only |
| `a / b` | `a / b`; `double` only — Dart's `/` always returns `double`, even for two `int`s, which the generator can't reproduce without a cast; convert an `int` with `.toDouble()` first |
| `-a` (unary) | `-a`; `int` or `double` |
| `x ~/= y` | `x /= y`; `int` only |
| `x %= y` | `x = dartrt.Mod(x, y)` — same reasoning as `%`; also valid as a `for`-loop updater; `int` only |
| `x /= y` | `x /= y`; `x` (and `y`) must be `double` — same reasoning as `/`. `i /= 2;` for an `int` `i` isn't valid Dart to begin with (`i`'s inferred type would be `double`), not merely unsupported syntax; use `~/=` for truncating `int` division |
| `x.toDouble()` (`x`: `int`) | `float64(x)` |
| `x.toInt()` (`x`: `double`) | `int(x)` — truncates toward zero, like Go's own `int` conversion |
| `x.round()` (`x`: `double`) | `int(math.Round(x))` — rounds half away from zero, matching Dart's `double.round()` |
| `print(<string>)` | `println(<string>)` — not `fmt.Println`, to avoid pulling in `fmt` on TinyGo |
| `print('... $x ...')` | string concatenation: `"... " + strconv.Itoa(x) + " ..."` |
| `sleep(Duration(milliseconds: n))` | `time.Sleep(n * time.Millisecond)` (also supports `seconds`/`minutes`/`hours`/`days`/`microseconds`, summed when combined) |
| `if (cond) { ... } else if (cond2) { ... } else { ... }` | `if cond { ... } else if cond2 { ... } else { ... }` — direct, same shape; every branch must be a `{ ... }` block |
| `a == b` / `a != b` / `a < b` / `a <= b` / `a > b` / `a >= b` | same tokens in Go. Both operands must have the same type (no implicit `int`/`double` promotion); `<`/`<=`/`>`/`>=` are further restricted to `int`/`double` |
| `a && b` / `a \|\| b` / `!a` | same tokens in Go; operands must be `bool` |
| `(expr)` | `(expr)` — parenthesization is preserved verbatim |

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

## Numeric semantics (decided 2026-09-22; `int` and `double` implemented)

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
- `int`/`double` arithmetic (`+`/`-`/`*`, unary `-`, and the compound forms
  `+=`/`-=`/`*=`) is implemented for matching operands (both `int` or both
  `double`, no implicit promotion); `~/`/`%`/`~/=`/`%=` are `int`-only, `/`/
  `/=` are `double`-only (Dart's `/` always returns `double`), see the v0.1
  table above.
- `int` ⇄ `double` conversion (`.toDouble()`/`.toInt()`/`.round()`) is
  implemented, restricted to the direction each bridges (`.toDouble()` on
  `int`, `.toInt()`/`.round()` on `double`) so every generated Go cast is
  meaningful rather than a redundant identity conversion.

## Type mapping table (decided 2026-09-22; "impl." marks what exists today)

| Dart | Go | Status |
| --- | --- | --- |
| `int` | `int` | impl. (literals/locals/binding results; `+`/`-`/`*`/`~/`/`%`, unary `-`, compound assignment, `.toDouble()`) |
| `double` | `float64`; `double d = 2;` → `d := 2.0` so Go doesn't infer `int` | impl. (literals/locals/binding results; `+`/`-`/`*`/`/`, unary `-`, compound assignment, `.toInt()`/`.round()`, string interpolation) |
| `bool` | `bool` | impl. (literals/locals/binding results; comparison/logical operators; `if`) |
| `String` | `string`; `.length` → `utf8.RuneCountInString` (UTF-16 vs UTF-8 differ outside the BMP); no indexing in v0.1 | impl. (literals/locals/binding results; no operations yet) |
| `Duration` | `time.Duration`; non-literal `Duration(milliseconds: n)` → `time.Duration(n) * time.Millisecond` | impl. (literals) |
| `List<T>` | `[]T`; `add` → `append`, `length` → `len`, indexing verbatim, `List.filled` → `make` + loop; growable/fixed not distinguished | decided (v0.2) |
| `enum` | `type E int` + `const ( ... iota )`; `.index` is the value, `.name` via a string table | decided (v0.2) |
| class (no inheritance) | `struct` + `NewFoo(...)` + pointer-receiver methods; instances are always `*Foo` (Dart reference semantics, `==` is identity) | decided (v0.2) |
| top-level function | `func`; positional parameters only, named/optional parameters rejected by the checker | decided |
| `if` / `else if` / `else` | direct; every branch must be a block (see the v0.1 table above) | impl. |
| `while` (general condition) / `for` (one declared variable, one updater) / `break` / `continue` | direct; see the v0.1 table above | impl. |
| `for-in` / `switch` | `for-in` → `range`; Dart `switch` does not fall through, so neither does the output | decided |
| cascade `a..b()..c()` | temporary + statement sequence | decided |
| `@GoType` class | the annotated Go type expression, verbatim | impl. |
| inheritance, mixins, generics, `T?`, `throw`/exceptions, `async` | rejected by the checker | decided (future) |

## Common Go runtime (`dartrt`, decided 2026-09-22, implemented)

Semantics that cannot be expressed as an inline Go expression go through a
small board-agnostic Go module at `packages/dart2tinygo/go/` (module
`github.com/o-ga09/dart2tinygo/packages/dart2tinygo/go`, imported as
`dartrt`), shipped and wired up exactly like a binding's `go/` (see
[`writing_bindings.md`](./writing_bindings.md)): the generator locates it via
`package:dart2tinygo`'s own package config (`Isolate.resolvePackageUri`),
since it isn't declared by any `@GoImport` — nothing in the entry point's
package graph otherwise points back at the transpiler's own package. It is
imported only when used. Contents: `Mod` (Dart `%`, used by `%` and `%=`,
implemented); `FormatDouble` (Dart prints `1.0`, Go's
`strconv.FormatFloat` prints `1`; implemented, wired into string
interpolation). This is language semantics, not board knowledge, so it does
not violate the core's no-board-code rule.

## String interpolation (implemented for `int` / `double` / `bool` / `String`)

- Do not use `fmt.Sprintf`. Concatenate with `strconv` etc. based on type, to avoid bloating the TinyGo binary.
- `int` → `strconv.Itoa`, `bool` → `strconv.FormatBool`, `String` → verbatim, `double` → `dartrt.FormatDouble`. The interpolated expression may be any supported value expression (literal, local, binding call, arithmetic, `.toDouble()`/`.toInt()`/`.round()`, Go constant), not only a local. `print(s)` likewise takes any `String` expression.

## Generated `go.mod`

- `go 1.25` (TinyGo 0.42's minimum); `go mod tidy` may raise it.
- One `require` + `replace` pair per in-tree Go runtime (bindings, `dartrt`).
