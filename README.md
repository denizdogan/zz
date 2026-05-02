# z

[![CI](https://github.com/denizdogan/z/actions/workflows/ci.yml/badge.svg)](https://github.com/denizdogan/z/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/denizdogan/z/branch/main/graph/badge.svg)](https://codecov.io/gh/denizdogan/z)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE.md)

Zod-like parsing and validation for Erlang.

`z` provides composable parser combinators that validate runtime data
against a schema and return either `{ok, Output}` or `{error, Errors}`
with structured error paths.

## Installation

Add to `rebar.config`:

```erlang
{deps, [{z, "0.1.0"}]}.
```

## Quick start

```erlang
Z = z:map(#{
    name => z:binary(),
    age => z:integer(#{min => 0}),
    tags => z:list(z:atom())
}),

{ok, _} = z:parse(Z, #{name => <<"alice">>, age => 30, tags => [admin]}).
```

## API

A parser is a `fun((term()) -> {ok, term()} | {error, [term()]})`. Run it
via `z:parse/2`.

### Atoms

```erlang
z:atom().
%% {error, [not_atom]} on non-atom input.
```

### Binaries

```erlang
z:binary().
z:binary(#{min => N, max => N, regex => Pattern}).
```

Errors: `not_binary`, `binary_too_short`, `binary_too_long`,
`regex_mismatch`. `min` and `max` measure `byte_size/1`. `regex` accepts
any `re:run/2`-compatible pattern.

### Booleans

```erlang
z:boolean().
%% {error, [not_boolean]} on non-boolean.
```

### Integers

```erlang
z:integer().
z:integer(#{min => N, max => N}).
```

Errors: `not_integer`, `integer_too_small`, `integer_too_large`.

### Floats

```erlang
z:float().
z:float(#{min => N, max => N}).
```

Errors: `not_float`, `float_too_small`, `float_too_large`. Integers are
not accepted — use `z:union([z:integer(), z:float()])` for either.

### Lists

```erlang
z:list().                         %% any list, contents not validated
z:list(z:integer()).              %% homogeneous list
z:list(z:integer(), #{min => 1, max => 10}).
z:list([z:integer(), z:binary()]).%% fixed-length, per-position parsers
```

Errors: `not_list`, `list_too_short`, `list_too_long`, `length_mismatch`
(fixed-length form). Element errors are wrapped as
`{list, Index, InnerErrors}` with 1-based `Index`.

### Maps

```erlang
z:map().                          %% any map, passthrough
z:map(Schema).                    %% schema with default unknown_keys => strip
z:map(Schema, #{unknown_keys => strip | passthrough | strict}).
```

`Schema` is a map of `Key => Parser | {optional, Parser}`. Use
`z:optional/1` to mark optional keys:

```erlang
z:map(#{
    id => z:integer(),
    nickname => z:optional(z:binary())
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
z:literal(42).
z:literal(<<"hello">>).
%% Matches with =:=. {error, [not_literal]} otherwise.
```

### Tuples

```erlang
z:tuple().                              %% any tuple, contents not validated
z:tuple([z:integer(), z:binary()]).     %% fixed-arity, per-position parsers
```

Errors: `not_tuple`, `arity_mismatch`. Element errors are wrapped as
`{tuple, Index, InnerErrors}` with 1-based `Index`.

### Unions

```erlang
z:union([z:integer(), z:binary()]).
%% First parser to succeed wins.
```

If no branch matches, the error is
`{error, [{no_match, [Errors1, Errors2, ...]}]}` where each entry is the
errors list from the corresponding parser, in input order. Empty union
yields `{error, [{no_match, []}]}`.

### Optional

`z:optional(Parser)` wraps a parser for use as a map schema value. Has no
effect outside a `z:map/1,2` schema.

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
Z = z:map(#{
    name => z:binary(),
    friends => z:list(z:map(#{age => z:integer(#{min => 0})}))
}),
z:parse(Z, #{name => 1, friends => [#{age => -1}]}).
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
