# Contributing

Thanks for considering a contribution.

## Development setup

This project uses [Mise](https://mise.jdx.dev/) for tool versions and
task running. With Mise installed, all tooling resolves automatically.

Required tools:

- Erlang/OTP 27 or newer (managed via Mise)
- rebar3 (managed via Mise)
- [`elp`](https://github.com/WhatsApp/erlang-language-platform) on
  `PATH` for eqwalizer checks (not managed by Mise; install from
  releases)

## Workflow

```console
$ mise compile        # compile
$ mise test           # eunit + proper
$ mise dialyzer       # static analysis
$ mise eq-all         # eqwalizer (requires elp)
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

1. Bump `vsn` in `src/zz.app.src` and convert the `[Unreleased]`
   heading in `CHANGELOG.md` to the new version. Update the version
   reference in `README.md`. Commit and push.
2. Run `mise check` to confirm everything is green.
3. Run `mise publish`. This publishes to Hex (requires
   `rebar3 hex user auth` once), tags `vX.Y.Z`, and pushes the tag.
