# Dart → Go conversion rules

**Languages:** English | [日本語](./mapping.ja.md)

Record conversion rules here once they're decided. Nothing has been decided yet.

## Numeric semantics (to be decided)

- Dart's `int` is assumed to be 64-bit. Whether the Go side uses `int64` or `int` is undecided.
- Note that Go's `int` becomes 32-bit on 32-bit MCUs (needs consideration).
- Since dart2js (Flutter Web) makes bitwise operations 32-bit, users who share code with Flutter will need a warning in the README (not yet started).

## Type mapping table (undefined)

| Dart | Go |
| --- | --- |
| (TBD) | (TBD) |

## String interpolation (policy only, not implemented)

- Do not use `fmt.Sprintf`. Concatenate with `strconv` etc. based on type, to avoid bloating the TinyGo binary.
