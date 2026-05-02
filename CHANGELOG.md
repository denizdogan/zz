# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `zz:issues/1` flattens nested `errors()` into a flat list of issue
  maps with `path` and `code`. `unknown_keys` issues carry `keys`;
  `no_match` issues carry `branches` (one nested issue list per union
  branch).
- New exported types: `issue/0`, `issues/0`, `path/0`.

## [0.1.0] - 2026-05-02

Initial public release.

### Added

- Parser combinators: `atom/0`, `binary/0,1`, `boolean/0`,
  `integer/0,1`, `float/0,1`, `list/0,1,2`, `literal/1`, `map/0,1,2`,
  `optional/1`, `tuple/0,1`, `union/1`.
- `parse/2` entry point.
- Map `unknown_keys` modes: `strip`, `passthrough`, `strict`.
- Property-based tests via PropEr.
- Public exported types: `parser/0`, `optional_parser/0`, `result/1`,
  `errors/0`, `binary_options/0`, `integer_options/0`, `float_options/0`,
  `list_options/0`, `map_options/0`, `schema/0`.
- eqwalizer-clean: `elp eqwalize-all` reports no errors.

[Unreleased]: https://github.com/denizdogan/zz/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/denizdogan/zz/releases/tag/v0.1.0
