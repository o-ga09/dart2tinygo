# Security Policy

**Languages:** English | [日本語](./SECURITY.ja.md)

## Reporting a vulnerability

If you find a security vulnerability in `dart2tinygo`, please **do not** open a public issue.

Instead, report it privately via [GitHub Security Advisories](https://github.com/o-ga09/dart2tinygo/security/advisories/new) for this repository. Please include:

- A description of the vulnerability and its potential impact
- Steps to reproduce (minimal Dart input, CLI command, etc.)
- The version/commit you tested against

We'll acknowledge your report and follow up as soon as possible. Since this project is small and early-stage, there is no formal SLA yet, but reports will be prioritized over other work.

## Scope

This policy covers the `dart2tinygo` CLI/transpiler and the packages in this repository (`tinygo_annotations`, `tinygo_machine`). Board-specific binding packages (e.g. a future `package:wio_terminal`) live in separate repositories and are out of scope here.
