# Writing bindings

**Languages:** English | [日本語](./writing_bindings.ja.md)

Board-specific support is not put into the core (`packages/dart2tinygo`); it's provided as separate binding packages.
The final annotation API should be decided while implementing, and reflected here once decided. It is currently unimplemented and undecided.

## Planned annotations (draft, not implemented)

- `@GoImport(path, alias: ...)`: declares a Go import at the library level
- `@GoName(name)`: the Go-side counterpart for a function, method, or constant
- `@GoType(name)`: the mapping between a Dart type and a Go type
