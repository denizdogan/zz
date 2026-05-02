# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Initial parser combinators: `atom/0`, `binary/0,1`, `boolean/0`,
  `integer/0,1`, `float/0,1`, `list/0,1,2`, `literal/1`, `map/0,1,2`,
  `optional/1`, `tuple/0,1`, `union/1`.
- `parse/2` entry point.
- Map `unknown_keys` modes: `strip`, `passthrough`, `strict`.
- Property-based tests via PropEr.
- Public exported types: `parser/0`, `optional_parser/0`, `result/1`,
  `errors/0`, `binary_options/0`, `integer_options/0`, `float_options/0`,
  `list_options/0`, `map_options/0`, `schema/0`.
- eqwalizer clean: `elp eqwalize-all` reports no errors. Wired into CI.
- `tuple/1` for fixed-arity tuples with per-position parsers, mirroring
  the heterogeneous form of `list/1`. Element errors are wrapped as
  `{tuple, Index, InnerErrors}`; arity violations return
  `[arity_mismatch]`.

### Changed

- `union/1` no-match errors now carry per-branch sub-errors so callers
  can see why each parser rejected the input. Format changed from
  `{error, [no_match]}` to
  `{error, [{no_match, [Errors1, Errors2, ...]}]}` (one sub-list per
  parser, in input order). Empty union yields
  `{error, [{no_match, []}]}`.
- `eqwalizer_support` moved from default deps to the test profile so
  the published Hex package has no runtime dependencies.

### Fixed

- `list/2` `min`/`max` length constraints were silently ignored due to a
  pattern mismatch on `maps:take/2`.

[Unreleased]: https://github.com/denizdogan/z/compare/HEAD...HEAD
