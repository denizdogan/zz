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
- `parser/1` and `optional_parser/1` types are now parameterized over
  the parsed value type, so `zz:parse/2` reports the precise output
  type (e.g. `parse(zz:integer(), X) -> result(integer())`).
  `parser/0` and `optional_parser/0` remain as `parser(term())` /
  `optional_parser(term())` aliases for back-compat.
- `zz:lazy/1` defers parser construction so schemas can reference
  themselves (recursive shapes like trees and JSON-like values).
- `zz:map_of/2` validates a homogeneous map: every key parsed by the
  first parser, every value by the second. Key errors surface as
  `{map_key, OriginalKey, InnerErrors}`; value errors as
  `{map_value, OriginalKey, InnerErrors}`. `zz:issues/1` flattens
  key errors as `code => invalid_key` issues with `key` and `errors`
  fields.
- `zz:char/0` validates a single Unicode codepoint (integer in
  `0..16#10FFFF`). `zz:char_list/0` validates a `[char()]`, the
  old-style Erlang string representation.
- `zz:pid/0` validates a process identifier. `zz:reference/0`
  validates a reference (e.g. from `make_ref/0`).
- `zz:iodata/0` validates `iodata()` (a binary or `iolist()`).
  `zz:iolist/0` validates an `iolist()` only (binary input rejected).
- `zz:number/0` validates an integer or float.
- `zz:enum/1` validates that input equals (`=:=`) one of a list of
  values; fails with `not_in_enum`.
- `zz:nullable/1` accepts `undefined` alongside the wrapped parser's
  values. Sugar for `union([literal(undefined), Z])`.

### Changed

- `zz:tuple/1` now takes a tuple of parsers instead of a list, so the
  schema mirrors the shape it validates: `zz:tuple({zz:integer(),
  zz:binary()})` instead of `zz:tuple([...])`.
- Map errors are now tagged symmetrically: `{map_value, K, [errs]}`
  for value-parser failures (was `{map, K, [errs]}`) and
  `{map_missing, K}` for required-key absences (was `{map, K,
  missing_key}`). Pattern matches on the old shapes need to update.

### Removed

- `zz:list/1` no longer accepts a list of parsers (the heterogeneous
  fixed-length form). Use `zz:tuple/1` for fixed-length heterogeneous
  data. The `length_mismatch` error code is gone.

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
