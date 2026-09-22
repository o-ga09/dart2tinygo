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
| `T name(<params>) { ... }` / `T name(<params>) => expr;` | `func name(<params>) T { ... }` — see "Top-level functions" below |
| `return expr;` / `return;` | `return expr` / `return` |
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

## Top-level functions (decided 2026-09-22, implemented)

Any number of top-level functions besides `main` map 1:1 onto Go `func`s in
the same generated file, in source order (purely for a readable diff — Go
doesn't care about declaration order, so forward references and recursion
both work without restriction).

- **Parameters are positional only.** Named parameters
  (`{required int x}`), optional positional parameters (`[int x = 0]`), and
  any default value are rejected — Go has no equivalent, and a struct-based
  mapping for named parameters may come later.
- **Parameter and return types**: `int`/`double`/`bool`/`String`/
  `List<int>`/`@GoType`, or `void` for the return type. The same "no casts"
  rule applies as everywhere else, so calling a function doesn't itself
  cast arguments — a call's own argument expressions are checked exactly
  like any other value expression.
- **A `@GoType` parameter or return type registers that binding's Go
  import**, even if the function's body never calls a method on it — unlike
  a local, whose import only gets registered when a binding call is
  actually written, a type that appears **only** in a signature would
  otherwise never trigger that registration.
- **`return expr;` / bare `return;`** inside a block body. Whether a bare
  `return;` (void) or a value (non-void) is required, and that the value's
  type matches the declared return type, is left to Dart's own analyzer —
  the same "trust Dart's own type-checking" precedent used elsewhere
  (e.g. `docs/mapping.md` doesn't re-verify `int += double` is invalid,
  since Dart already rejects it).
- **An expression body (`=> expr;`)** works for both non-void functions
  (becomes `return expr`) and `void` ones (`void f() => print(s);` is
  idiomatic Dart; since Go rejects `return <value>` in a function with no
  declared return type, this becomes `expr` as its own statement, checked
  the same way an `ExpressionStatement` is — so only expressions the
  generator can emit as a statement are accepted there, not any value
  expression).
- **Calling a function declared in this file** (not an `external` binding)
  maps to a plain Go call of the same name — as a statement (discarding a
  non-void result, like a binding call) or as a value expression.
- Closures, function values, and function-typed parameters are out of
  scope — a `FunctionDeclaration` is the only function shape recognized;
  anything that tries to use a function as a value (assign it to a
  variable, pass it as an argument) is rejected as an unsupported
  expression, since no code path treats a bare function reference as one.

## Annotation bindings (decided, implemented)

Calls into `@GoName` declarations (see [`writing_bindings.md`](./writing_bindings.md))
map 1:1 onto Go calls; the transpiler adds no wrapper code of its own.

| Dart | Go |
| --- | --- |
| `@GoImport('pkg/path', alias: 'p')` on the binding library | `import p "pkg/path"` (only when a binding from that library is used; without `alias`, `import "pkg/path"`) |
| `final d = newDisplay();` where `newDisplay` is `@GoName('wio.NewDisplay')` | `d := wio.NewDisplay()` (`final`/`var` make no difference; Go infers the `@GoType`) |
| `beep(3);` where `beep` is `@GoName('rt.Beep')` | `rt.Beep(3)` |
| `d.drawText(10, 20, 'hi');` where `drawText` is `@GoName('DrawText')` | `d.DrawText(10, 20, "hi")` |
| `newDisplay().clear();` (method chaining on a call result, see #30) | `wio.NewDisplay().Clear()` — the receiver is emitted verbatim, at any chaining depth |
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

## `List<int>` (decided 2026-09-22, implemented)

`List<int>` maps to Go's `[]byte`, not `[]int` — the SD-card, I2C/UART, and
Wi-Fi/HTTP bindings this exists for all speak `[]byte` (`io.Reader`/
`io.Writer`, `strconv`, network buffers), and Dart itself uses `List<int>`
as its byte-buffer type (`Uint8List` extends it). This is narrower than the
`List<T>` → `[]T` mapping decided for v0.2 generically; other element types
(`List<double>`, `List<String>`, …) stay out of scope until then.

Dart's element type is `int`, but Go's `[]byte` element type is `byte`
(`uint8`), so every read/write crosses that boundary with an explicit,
generator-inserted cast — the same kind of deliberate conversion already
used for `.toDouble()`/`.toInt()`/`.round()`, not a "no casts" violation:

| Dart | Go |
| --- | --- |
| `<int>[1, 2, 3]` (or an inferred `[1, 2, 3]`) | `[]byte{byte(1), byte(2), byte(3)}` |
| `data[i]` (read) | `int(data[i])` |
| `data[i] = v;` (write; only plain `=`) | `data[i] = byte(v)` |
| `data.add(v);` | `data = append(data, byte(v))` — Dart's `List.add` mutates in place and returns `void`; Go's `append` returns a new slice that must be reassigned |
| `data.length` | `len(data)` |
| `String.fromCharCodes(data)` | `string(data)` — a named constructor (`InstanceCreationExpression`, the same AST shape as `Duration(...)`), not a static method call |
| `s.codeUnits` | `[]byte(s)` |

List equality (`a == b`) is not supported: Go slices aren't comparable with
`==` (a compile error, except against `nil`), so this is rejected by the
existing "operands must have the same type" comparison rule, which never
lists `List<int>` as a comparable type.

## `String` operations (decided 2026-09-22, implemented)

`.length` and `.substring` are **byte-indexed**, matching Go's own `len(s)`
and `s[start:end]` exactly — not Dart's UTF-16 code-unit indexing. This
supersedes an earlier placeholder in this doc that proposed
`utf8.RuneCountInString` for `.length`: that was never implemented, and
would have been its own imperfect approximation of Dart's semantics (Unicode
code points, not UTF-16 code units — still wrong for astral characters,
just differently), while also being unusable by `.substring`, which needs
byte or rune indices, not code-unit ones, to slice Go's own `string`. Plain
byte length/slicing is simpler, composes correctly with itself
(`s.substring(0, s.length)` always returns the whole string), and is exact
for the overwhelmingly common ASCII case (config keys, protocol headers,
formatted numbers); it differs from Dart's result only for non-ASCII text,
the same class of BMP/astral caveat every other option here also has.

| Dart | Go |
| --- | --- |
| `a.length` (`a`: `String`) | `len(a)` |
| `a + b` (`a`, `b`: `String`) | `a + b` — same token, same semantics as Go's own `+` |
| `a.substring(start)` / `a.substring(start, end)` | `a[start:]` / `a[start:end]` |
| `a.codeUnits` | `[]byte(a)` (see "List<int>" above) |

## Switch statements (decided 2026-09-22, implemented)

`switch` maps onto Go's own `switch`, which shares Dart 3's no-fallthrough
semantics: neither language falls through into the next case by default, so
the generator needs no `break` to terminate a case (a bare `break;` inside a
`switch` case is not specially handled in v0.1 — it goes through the same
"only inside a while/for loop" check as everywhere else, since none of the
motivating use cases need it yet).

Restricted to constant-value cases on an `int`/`String`/`bool` scrutinee —
Go's `switch` has no pattern matching, so a Dart 3 pattern other than a bare
constant (`case var x:`, destructuring, object patterns) is rejected by the
checker, as is a `case ... when ...` guard and a labeled case.

| Dart | Go |
| --- | --- |
| `switch (x) { case 0: ...; case 1: ...; default: ...; }` | `switch x { case 0: ...; case 1: ...; default: ...; }` — direct |
| `case a: case b: <body>` (consecutive empty cases) | `case a, b: <body>` — Dart's case-grouping syntax isn't a statement, so adjacent empty cases are merged into one Go `case` clause with a comma-separated value list |
| `case a: /* nothing, falls into default */ default: <body>` | `default: <body>` (the `a` case is dropped, not merged) — Go's `default` has no value list, but it already matches any value no explicit `case` claims, which is exactly what an empty case falling into `default` means |
| `case 'x':` / `case true:` | `case "x":` / `case true:` — the case value must be a literal of the scrutinee's own type, no implicit conversion |

Out of scope for v0.1: `case ... when ...` guards, non-constant/destructuring
patterns, `for-in`/`for-loop`-in-`switch` label targets, and enum-value
cases (blocked on `enum` support, see the type mapping table).

## Cascades (decided 2026-09-22, implemented)

`a..b()..c()` isn't a single Go expression — Go has nothing that reads a
value and performs a sequence of calls on it without repeating the receiver
— so it becomes a temporary plus a statement sequence, per HANDOFF
§4.4's own `Pin.led..configure(...)` example. Restricted to a `@GoType`
binding value, and every cascade section must be a bare `..method(args)`
binding call (v0.1 has no classes/fields of its own to make a cascaded
getter/setter/index section meaningful).

| Dart | Go |
| --- | --- |
| `newDisplay()..clear()..drawText(40, 120, 'Hi');` (a statement) | `_t0 := wio.NewDisplay()` then `_t0.Clear()` then `_t0.DrawText(40, 120, "Hi")` — a synthetic `_t0`/`_t1`/... receiver, unique across the whole generated file |
| `final d = newDisplay()..clear();` (a local's initializer) | `d := wio.NewDisplay()` then `d.Clear()` — the local's own name is reused as the receiver, no synthetic temp needed |

## Type mapping table (decided 2026-09-22; "impl." marks what exists today)

| Dart | Go | Status |
| --- | --- | --- |
| `int` | `int` | impl. (literals/locals/binding results; `+`/`-`/`*`/`~/`/`%`, unary `-`, compound assignment, `.toDouble()`) |
| `double` | `float64`; `double d = 2;` → `d := 2.0` so Go doesn't infer `int` | impl. (literals/locals/binding results; `+`/`-`/`*`/`/`, unary `-`, compound assignment, `.toInt()`/`.round()`, string interpolation) |
| `bool` | `bool` | impl. (literals/locals/binding results; comparison/logical operators; `if`) |
| `String` | `string`; `.length` → `len(s)` (byte length — see "List<int>" below for the rationale); `+` concatenation; `.substring`; no general indexing in v0.1 | impl. (literals/locals/binding results, `+`, `.substring()`, `.length`, `.codeUnits`) |
| `Duration` | `time.Duration`; non-literal `Duration(milliseconds: n)` → `time.Duration(n) * time.Millisecond` | impl. (literals) |
| `List<int>` | `[]byte` — see "List<int>" below | impl. |
| `List<T>` (`T` other than `int`) | `[]T`; `add` → `append`, `length` → `len`, indexing verbatim, `List.filled` → `make` + loop; growable/fixed not distinguished | decided (v0.2) |
| `enum` | `type E int` + `const ( ... iota )`; `.index` is the value, `.name` via a string table | decided (v0.2) |
| class (no inheritance) | `struct` + `NewFoo(...)` + pointer-receiver methods; instances are always `*Foo` (Dart reference semantics, `==` is identity) | decided (v0.2) |
| top-level function | `func`; positional parameters only, named/optional parameters rejected by the checker — see "Top-level functions" above | impl. |
| `if` / `else if` / `else` | direct; every branch must be a block (see the v0.1 table above) | impl. |
| `while` (general condition) / `for` (one declared variable, one updater) / `break` / `continue` | direct; see the v0.1 table above | impl. |
| `for-in` | → `range` | decided (v0.2) |
| `switch` | `switch`; constant `int`/`String`/`bool` cases only, no fallthrough, empty cases merge/drop — see "Switch statements" above | impl. |
| cascade `a..b()..c()` on a `@GoType` binding value | temporary (or the local's own name, as an initializer) + statement sequence — see "Cascades" above | impl. |
| method chaining `a().b()` on a binding call result | direct — see "Annotation bindings" above | impl. |
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
