# Contributing

Thanks for considering a contribution.

## Development setup

This project uses [Mise](https://mise.jdx.dev/) for tool versions and
task running. With Mise installed, all tooling resolves automatically.

Required tools:

- Erlang/OTP 27 or newer (managed via Mise)
- rebar3 (managed via Mise)
- [`elp`](https://github.com/WhatsApp/erlang-language-platform) for
  Eqwalizer checks (managed via Mise)

Tool versions are pinned in `mise.toml`, with resolved artifacts and checksums
in `mise.lock`. After changing a tool version, run `mise lock` and commit both
files. Rebar plugins are pinned explicitly because Rebar does not include
plugins in `rebar.lock`. Review `eqwalizer_support` compatibility when
upgrading ELP.

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

Run `mise check` before opening a pull request. CI runs the same
checks on OTP 27, 28, and 29.

To exercise the GitHub Actions workflow itself, start Docker and run
`mise ci-local`. This uses [`act`](https://nektosact.com/) to run the full
OTP 27–29 matrix in Linux containers. Compilation, tests, coverage, and
Dialyzer run on every version; Eqwalizer runs once on OTP 28 because ELP does
not publish an OTP 29 runtime build and does not yet support OTP 29-generated
stdlib artifacts ([upstream issue #214](https://github.com/WhatsApp/erlang-language-platform/issues/214)). GitHub cache operations and Codecov are
skipped locally because their backing services are unavailable outside
Actions. The complete matrix is considerably slower and uses more disk space
than `mise check`.

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
