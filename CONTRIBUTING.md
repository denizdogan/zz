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
```

Run `mise check` before opening a pull request. CI runs the same
checks on OTP 27 and 28.

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
