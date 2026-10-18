# Contributing

Thanks for considering a contribution.

## Development setup

This project uses [Mise](https://mise.jdx.dev/) for tool versions and
task running. With Mise installed, all tooling resolves automatically.

Required tools:

- Erlang/OTP 27 or newer (Mise pins OTP 29.1.2 for development)
- rebar3 (managed via Mise)
- [`elp`](https://github.com/WhatsApp/erlang-language-platform) for
  Eqwalizer checks (managed via Mise)

Tool versions are pinned in `mise.toml`, with resolved artifacts and checksums
in `mise.lock`. After changing a tool version, run `mise lock` and commit both
files. Rebar plugins are pinned explicitly because Rebar does not include
plugins in `rebar.lock`. ELP bundles `eqwalizer_support`; this project does
not need a separate dependency because its specs do not reference
`eqwalizer` types. Keep ELP's OTP artifact suffix aligned with the managed
runtime when upgrading. Eqwalizer tasks and Zed clear `ELP_EQWALIZER_PATH`
before invoking `mise exec -- elp` directly, so local ELP debug builds on
`PATH` do not override the managed binary.

## Workflow

```console
$ mise compile        # compile
$ mise test           # eunit + proper
$ mise dialyzer       # static analysis
$ mise eq-all         # eqwalizer
$ mise format         # apply erlfmt
$ mise check          # everything above, in sequence
$ mise ci-local       # validate workflows + run all CI versions in Docker
```

Run `mise check` before opening a pull request. CI runs compilation,
formatting, EUnit, PropEr, coverage, and Dialyzer on the latest patches of
OTP 27, 28, and 29. Compiler warnings are errors for project code and tests;
documentation and Eqwalizer run once on OTP 29.

To exercise the GitHub Actions workflow itself, start Docker and run
`mise ci-local`. This uses [`act`](https://nektosact.com/) to run the full
OTP 27–29 matrix in Linux containers. Compilation, tests, coverage, and
Dialyzer run on every version; documentation and Eqwalizer run on OTP 29
using ELP's OTP 29.1 build. GitHub cache operations and Codecov are
skipped locally because their backing services are unavailable outside
Actions. The complete matrix is considerably slower and uses more disk space
than `mise check`.

## OTP 29 compatibility

The current development baseline is [OTP 29.1.2](https://github.com/erlang/otp/releases/tag/OTP-29.1.2).
The [OTP 29.0 release notes](https://github.com/erlang/otp/releases/tag/OTP-29.0)
and [OTP 29.1 release notes](https://github.com/erlang/otp/releases/tag/OTP-29.1)
were reviewed for language, compiler, and standard-library changes:

- Keep production syntax and APIs compatible with OTP 27. New features such
  as `is_integer/3`, chained function calls, multi-valued comprehensions, and
  experimental native-record declarations are not required by zz.
- Native records are a distinct data type, not tuples or maps. Generic
  parsers accept them as opaque values; `tuple` and `map` parsers reject
  them. `test/otp29_tests.erl` uses reflection-created fixtures and is gated
  on OTP 29 so older runtimes still compile the test suite.
- Map iteration order remains unspecified across releases. OTP 29's
  consistency between iteration APIs does not make validation issue order
  or collision-overwrite winners deterministic.
- The code does not use the affected `array`, `gb_sets:from_ordset/1`,
  `gb_trees:from_orddict/1`, or `beam_lib` error representations, nor the
  deprecated catch expressions or comprehension-qualifier assignments.
- CI caches use the resolved OTP patch version to avoid reusing BEAM files
  and Dialyzer PLTs across runtime upgrades.

ELP [2026-10-14](https://github.com/WhatsApp/erlang-language-platform/releases/tag/2026-10-14)
provides OTP 29.1 artifacts and bundled Eqwalizer support, removing the old
OTP 28-only tooling restriction. See its [Rebar3 setup documentation](https://whatsapp.github.io/erlang-language-platform/docs/get-started/configure-project/rebar3/).

## Conventions

- **Formatting:** [`erlfmt`](https://github.com/whatsapp/erlfmt) — CI
  enforces with `rebar3 fmt --check`.
- **Type checking:** dialyzer must report 0 warnings; eqwalizer must
  report `NO ERRORS`.
- **Tests:** prefer one focused EUnit function per behaviour. Use
  PropEr for property-based coverage where it adds signal.
- **Commits:** short imperative subject lines (e.g. `Add tuple/1`,
  `Fix list/2 length guard`). Reference an issue if relevant.

## Releasing (maintainers)

1. Bump `vsn` in `src/zz.app.src`, move the current `[Unreleased]`
   entries into a new version section while keeping an empty
   `[Unreleased]` heading, and update the version in `README.md` and the
   changelog links.
2. Commit and push to `main`, then wait for CI to pass.
3. Run `mise publish` (requires `rebar3 hex user auth` once). The task
   verifies a clean, synchronized `main`, checks version consistency and
   tag availability, runs the full validation suite, builds the package,
   pushes the version tag, and publishes to Hex.
