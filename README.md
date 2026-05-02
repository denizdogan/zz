# zz

[![CI](https://github.com/denizdogan/zz/actions/workflows/ci.yml/badge.svg)](https://github.com/denizdogan/zz/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/denizdogan/zz/branch/main/graph/badge.svg)](https://codecov.io/gh/denizdogan/zz)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE.md)

Zod-like parsing and validation for Erlang.

`zz` provides composable parser combinators that validate runtime data
against a schema and return either `{ok, Output}` or `{error, Errors}`
with structured error paths.

## Installation

Add to `rebar.config`:

```erlang
{deps, [{zz, "0.1.0"}]}.
```

## Quick start

```erlang
Z = zz:map(#{
    name => zz:binary(),
    age => zz:integer(#{min => 0}),
    tags => zz:list(zz:atom())
}),

{ok, _} = zz:parse(Z, #{name => <<"alice">>, age => 30, tags => [admin]}).
```

## API

A parser is a `fun((term()) -> {ok, term()} | {error, [term()]})`. Run it
via `zz:parse/2`.

### Atoms

```erlang
zz:atom().
%% {error, [not_atom]} on non-atom input.
```

### Binaries

```erlang
zz:binary().
zz:binary(#{min => N, max => N, regex => Pattern}).
```

Errors: `not_binary`, `binary_too_short`, `binary_too_long`,
`regex_mismatch`. `min` and `max` measure `byte_size/1`. `regex` accepts
any `re:run/2`-compatible pattern.

### Booleans

```erlang
zz:boolean().
%% {error, [not_boolean]} on non-boolean.
```

### Integers

```erlang
zz:integer().
zz:integer(#{min => N, max => N}).
```

Errors: `not_integer`, `integer_too_small`, `integer_too_large`.

### Floats

```erlang
zz:float().
zz:float(#{min => N, max => N}).
```

Errors: `not_float`, `float_too_small`, `float_too_large`. Integers are
not accepted — use `zz:union([zz:integer(), zz:float()])` for either.

### Lists

```erlang
zz:list().                         %% any list, contents not validated
zz:list(zz:integer()).              %% homogeneous list
zz:list(zz:integer(), #{min => 1, max => 10}).
zz:list([zz:integer(), zz:binary()]).%% fixed-length, per-position parsers
```

Errors: `not_list`, `list_too_short`, `list_too_long`, `length_mismatch`
(fixed-length form). Element errors are wrapped as
`{list, Index, InnerErrors}` with 1-based `Index`.

### Maps

```erlang
zz:map().                          %% any map, passthrough
zz:map(Schema).                    %% schema with default unknown_keys => strip
zz:map(Schema, #{unknown_keys => strip | passthrough | strict}).
```

`Schema` is a map of `Key => Parser | {optional, Parser}`. Use
`zz:optional/1` to mark optional keys:

```erlang
zz:map(#{
    id => zz:integer(),
    nickname => zz:optional(zz:binary())
}).
```

`unknown_keys` modes:

- `strip` (default for `map/1,2`) — drop keys not in `Schema` from output.
- `passthrough` (default for `map/0`) — keep unknown keys in output.
- `strict` — emit `{unknown_keys, [Key]}` error.

Errors: `not_map`, `{map, Key, missing_key}`, `{map, Key, InnerErrors}`,
`{unknown_keys, [Key]}`.

### Literals

```erlang
zz:literal(42).
zz:literal(<<"hello">>).
%% Matches with =:=. {error, [not_literal]} otherwise.
```

### Tuples

```erlang
zz:tuple().                              %% any tuple, contents not validated
zz:tuple([zz:integer(), zz:binary()]).     %% fixed-arity, per-position parsers
```

Errors: `not_tuple`, `arity_mismatch`. Element errors are wrapped as
`{tuple, Index, InnerErrors}` with 1-based `Index`.

### Unions

```erlang
zz:union([zz:integer(), zz:binary()]).
%% First parser to succeed wins.
```

If no branch matches, the error is
`{error, [{no_match, [Errors1, Errors2, ...]}]}` where each entry is the
errors list from the corresponding parser, in input order. Empty union
yields `{error, [{no_match, []}]}`.

### Optional

`zz:optional(Parser)` wraps a parser for use as a map schema value. Has no
effect outside a `zz:map/1,2` schema.

## Error format

Errors are a list. Each entry is either a leaf atom (`not_atom`,
`integer_too_small`, ...) or a tagged tuple locating the failure inside a
nested structure:

```erlang
{list, Index, InnerErrors}
{tuple, Index, InnerErrors}
{map, Key, InnerErrors}
{map, Key, missing_key}
{unknown_keys, [Key]}
{no_match, [Errors1, Errors2, ...]}
```

Multiple errors at the same level accumulate.

```erlang
Z = zz:map(#{
    name => zz:binary(),
    friends => zz:list(zz:map(#{age => zz:integer(#{min => 0})}))
}),
zz:parse(Z, #{name => 1, friends => [#{age => -1}]}).
%% {error, [
%%     {map, name, [not_binary]},
%%     {map, friends, [{list, 1, [{map, age, [integer_too_small]}]}]}
%% ]}
```

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full setup. Quick start
with [Mise](https://mise.jdx.dev/):

```console
$ mise compile
$ mise test
$ mise check      # everything: fmt, eunit, proper, dialyzer, eqwalizer
$ mise docs
```

```console
$ git config --local blame.ignoreRevsFile .git-blame-ignore-revs
```

## License

[Apache-2.0](LICENSE.md)
