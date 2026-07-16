# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-07-16

### Added

- Added `zz:map_of/3` and exported `t:zz:map_of_options/0`; set
  `on_collision => overwrite` to intentionally allow transformed-key
  collisions.

### Changed

- `zz:map_of/2,3` now rejects transformed-key collisions by default with
  `{map_key_collision, ParsedKey}` instead of silently overwriting an entry.
  `zz:issues/1` exposes these as `map_key_collision` issues with
  `key => ParsedKey`.
- `zz:binary/1` now compiles source regex patterns when the parser is
  constructed, accepts precompiled `re:mp()` patterns, and raises
  `error:{invalid_regex, Reason}` for malformed patterns.

### Fixed

- `zz:map/2` with `unknown_keys => strict` no longer reports
  `{unknown_keys, []}` when the input contains no unknown keys.
- `zz:map/2` and `zz:map_of/3` now raise `badarg` at parser construction for
  invalid `unknown_keys` and `on_collision` values instead of failing later or
  silently allowing transformed-key collisions.
- `zz:issues/1` now preserves enclosing paths inside nested union branch
  issues.
- `zz:list/0,1,2` and `zz:char_list/0` now reject improper lists with
  `{error, [not_list]}` instead of accepting them or crashing.
- `zz:binary/1` now returns `regex_mismatch` instead of crashing when a Unicode
  regex receives invalid UTF-8 input.
- `zz:map_of/2,3` now validates keys and values independently, accumulating
  value failures alongside key-validation and transformed-key collision
  failures.
- `zz:list/2` now reports every violated length constraint, including both
  `list_too_short` and `list_too_long` for contradictory bounds.

### Tooling

- Extended CI to OTP 29 and added `mise ci-local` to lint and run the OTP 27–29
  workflow matrix with `act`.
- Pinned Mise-managed tools and Rebar plugins, added `mise.lock`, and configured
  Zed to use the managed ELP and Eqwalizer setup.
- Hardened `mise publish` with clean and synchronized branch checks, release
  metadata and tag validation, the full check suite, and a Hex package build
  before tagging and publishing.

## [0.2.1] - 2026-05-02

### Changed

- Performance: scalar parser options are now extracted at parser
  construction time rather than folded over the options map on every
  parse call. `map/0` short-circuits to a plain `is_map` check. Median
  speedups (1M iter, OTP 28 / ARM macOS): `binary/1`, `integer/1`,
  `float/1` with options ~5x; `map/0` ~6x; `list/1,2` over 100
  elements ~2x; `map/1,2` schemas 1.2-1.4x; `map_of/2` 1.4x. See
  `test/zz_bench.erl`.

### Fixed

- Doc type cross-references in README and CHANGELOG now use
  module-qualified syntax (`t:zz:parser/1`, `t:zz:issues/0`),
  eliminating ex_doc warnings on publish.

### Tooling

- Added `mise format-check` task (parity with CI's `rebar3 fmt
  --check`).
- Added `mise bench` task and `test/zz_bench.erl` micro-benchmark
  harness.
- Added `CODE_OF_CONDUCT.md`.
- Split `integer_typed_tests` into `pos_integer_tests`,
  `non_neg_integer_tests`, `neg_integer_tests` for consistency with
  the one-file-per-function project convention.

## [0.2.0] - 2026-05-02

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
- `zz:any/0` accepts any input, output equals input. Useful as a
  placeholder.
- `zz:bitstring/0,1` validates a bitstring, with optional `min`/`max`
  `bit_size/1` constraints.
- `zz:function/0` validates any function. `zz:function/1` validates a
  function with the given arity.
- `zz:pos_integer/0`, `zz:non_neg_integer/0`, `zz:neg_integer/0`
  validate the corresponding integer subtypes.
- `zz:format_issues/1` formats `t:zz:issues/0` as a human-readable
  binary, one issue per line.

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

[Unreleased]: https://github.com/denizdogan/zz/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/denizdogan/zz/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/denizdogan/zz/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/denizdogan/zz/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/denizdogan/zz/tree/v0.1.0
