-module(zz).

-moduledoc """
Zod-like parsing and validation for Erlang.

Each combinator returns a `t:parser/1` (or `t:optional_parser/1` from
`optional/1`). Compose them, then run with `parse/2`:

```erlang
Z = zz:map(#{name => zz:binary(), age => zz:integer(#{min => 0})}),
{ok, _} = zz:parse(Z, #{name => <<"x">>, age => 1}).
```

On failure, the nested `t:errors/0` shape can be flattened to a
path-addressed list of issues with `issues/1`.
""".

-compile({no_auto_import, [float/1]}).

-export([
    atom/0,
    binary/0,
    binary/1,
    boolean/0,
    float/0,
    float/1,
    integer/0,
    integer/1,
    issues/1,
    lazy/1,
    list/0,
    list/1,
    list/2,
    literal/1,
    map/0,
    map/1,
    map/2,
    map_of/2,
    optional/1,
    parse/2,
    tuple/0,
    tuple/1,
    union/1
]).

-export_type([
    parser/0,
    parser/1,
    optional_parser/0,
    optional_parser/1,
    result/1,
    errors/0,
    issue/0,
    issues/0,
    path/0,
    binary_options/0,
    integer_options/0,
    float_options/0,
    list_options/0,
    map_options/0,
    schema/0
]).

-type result(T) :: {ok, T} | {error, errors()}.
-type errors() :: [error()].
-type error() ::
    atom()
    | {list, pos_integer(), errors()}
    | {tuple, pos_integer(), errors()}
    | {map_key, term(), errors()}
    | {map_value, term(), errors()}
    | {map_missing, term()}
    | {unknown_keys, [term()]}
    | {no_match, [errors()]}.

-type parser(T) :: fun((term()) -> result(T)).
-type parser() :: parser(term()).
-type optional_parser(T) :: {optional, parser(T)}.
-type optional_parser() :: optional_parser(term()).

-type path() :: [term()].
-type issue() :: #{path := path(), code := atom(), _ => _}.
-type issues() :: [issue()].

-type binary_options() :: #{
    min => non_neg_integer(),
    max => non_neg_integer(),
    regex => iodata()
}.
-type integer_options() :: #{min => integer(), max => integer()}.
-type float_options() :: #{min => float(), max => float()}.
-type list_options() :: #{min => non_neg_integer(), max => non_neg_integer()}.
-type map_options() :: #{unknown_keys => strip | passthrough | strict}.
-type schema() :: #{term() => parser() | optional_parser()}.

-doc "Run parser `Z` against `Input`.".
-spec parse(parser(T), term()) -> result(T).
parse(Z, Input) ->
    Z(Input).

-doc "Validate that input is an atom.".
-spec atom() -> parser(atom()).
atom() ->
    fun
        (Input) when is_atom(Input) ->
            {ok, Input};
        (_Invalid) ->
            {error, [not_atom]}
    end.

-doc #{equiv => binary / 1}.
-spec binary() -> parser(binary()).
binary() ->
    binary(#{}).

-doc """
Validate that input is a binary, with optional `min`/`max` byte size and
`regex` constraints.
""".
-spec binary(binary_options()) -> parser(binary()).
binary(Options) ->
    fun
        (Input) when is_binary(Input) ->
            Errors =
                maps:fold(
                    fun
                        (min, Min, Es) when byte_size(Input) < Min ->
                            [binary_too_short | Es];
                        (min, _Min, Es) ->
                            Es;
                        (max, Max, Es) when byte_size(Input) > Max ->
                            [binary_too_long | Es];
                        (max, _Max, Es) ->
                            Es;
                        (regex, Regex, Es) when is_binary(Regex); is_list(Regex) ->
                            case re:run(Input, Regex) of
                                nomatch ->
                                    [regex_mismatch | Es];
                                _ ->
                                    Es
                            end
                    end,
                    [],
                    Options
                ),
            case Errors of
                [] ->
                    {ok, Input};
                _ ->
                    {error, Errors}
            end;
        (_Invalid) ->
            {error, [not_binary]}
    end.

-doc "Validate that input is a boolean.".
-spec boolean() -> parser(boolean()).
boolean() ->
    fun
        (Input) when is_boolean(Input) ->
            {ok, Input};
        (_Invalid) ->
            {error, [not_boolean]}
    end.

-doc #{equiv => integer / 1}.
-spec integer() -> parser(integer()).
integer() ->
    integer(#{}).

-doc "Validate that input is an integer, with optional `min`/`max`.".
-spec integer(integer_options()) -> parser(integer()).
integer(Options) ->
    fun
        (Input) when is_integer(Input) ->
            Errors =
                maps:fold(
                    fun
                        (min, Min, Es) when Input < Min ->
                            [integer_too_small | Es];
                        (min, _Min, Es) ->
                            Es;
                        (max, Max, Es) when Input > Max ->
                            [integer_too_large | Es];
                        (max, _Max, Es) ->
                            Es
                    end,
                    [],
                    Options
                ),
            case Errors of
                [] ->
                    {ok, Input};
                _ ->
                    {error, Errors}
            end;
        (_Invalid) ->
            {error, [not_integer]}
    end.

-doc #{equiv => float / 1}.
-spec float() -> parser(float()).
float() ->
    float(#{}).

-doc "Validate that input is a float, with optional `min`/`max`.".
-spec float(float_options()) -> parser(float()).
float(Options) ->
    fun
        (Input) when is_float(Input) ->
            Errors =
                maps:fold(
                    fun
                        (min, Min, Es) when Input < Min ->
                            [float_too_small | Es];
                        (min, _Min, Es) ->
                            Es;
                        (max, Max, Es) when Input > Max ->
                            [float_too_large | Es];
                        (max, _Max, Es) ->
                            Es
                    end,
                    [],
                    Options
                ),
            case Errors of
                [] ->
                    {ok, Input};
                _ ->
                    {error, Errors}
            end;
        (_Invalid) ->
            {error, [not_float]}
    end.

-doc "Validate that input is a list (any contents).".
-spec list() -> parser([term()]).
list() ->
    fun
        (Input) when is_list(Input) ->
            {ok, Input};
        (_Invalid) ->
            {error, [not_list]}
    end.

-doc #{equiv => list / 2}.
-spec list(parser(T)) -> parser([T]).
list(Z) ->
    list(Z, #{}).

-doc """
Validate a homogeneous list, parsing each element with `Z`. Optional
`min`/`max` constrain length.
""".
-spec list(parser(T), list_options()) -> parser([T]).
list(Z, Options) ->
    fun
        (Input) when is_list(Input) ->
            case maps:get(max, Options, infinity) of
                Max when is_integer(Max), length(Input) > Max ->
                    {error, [list_too_long]};
                _ ->
                    case maps:get(min, Options, 0) of
                        Min when is_integer(Min), length(Input) < Min ->
                            {error, [list_too_short]};
                        _ ->
                            {_, O1, E1} =
                                lists:foldl(
                                    fun(I, {N, Os, Es}) ->
                                        case Z(I) of
                                            {ok, O} ->
                                                {N + 1, [O | Os], Es};
                                            {error, E} ->
                                                {N + 1, Os, [{list, N, E} | Es]}
                                        end
                                    end,
                                    {1, [], []},
                                    Input
                                ),
                            case E1 of
                                [] ->
                                    {ok, lists:reverse(O1)};
                                _ ->
                                    {error, lists:reverse(E1)}
                            end
                    end
            end;
        (_Invalid) ->
            {error, [not_list]}
    end.

-doc "Validate that input equals `Value` exactly (`=:=`).".
-spec literal(T) -> parser(T).
literal(Value) ->
    fun
        (Input) when Input =:= Value ->
            {ok, Value};
        (_Invalid) ->
            {error, [not_literal]}
    end.

-doc "Validate that input is a map (passthrough on contents).".
-spec map() -> parser(#{term() => term()}).
map() ->
    map(#{}, #{unknown_keys => passthrough}).

-doc #{equiv => map / 2}.
-spec map(schema()) -> parser(#{term() => term()}).
map(Schema) ->
    map(Schema, #{}).

-doc """
Validate a map against `Schema`. `unknown_keys` controls handling of keys
not in `Schema`: `strip` (drop, default), `passthrough` (keep), `strict`
(error).
""".
-spec map(schema(), map_options()) -> parser(#{term() => term()}).
map(Schema, Options) ->
    fun
        (Input) when is_map(Input) ->
            {Output1, RemainingMap, Errors1} =
                maps:fold(
                    fun
                        (K, {optional, Z}, {Os, Is, Es}) ->
                            case maps:take(K, Is) of
                                error ->
                                    {Os, Is, Es};
                                {Value, Rest} ->
                                    case Z(Value) of
                                        {ok, O} ->
                                            {Os#{K => O}, Rest, Es};
                                        {error, E} ->
                                            {Os, Rest, [{map_value, K, E} | Es]}
                                    end
                            end;
                        (K, Z, {Os, Is, Es}) ->
                            case maps:take(K, Is) of
                                error ->
                                    {Os, Is, [{map_missing, K} | Es]};
                                {Value, Rest} ->
                                    case Z(Value) of
                                        {ok, O} ->
                                            {Os#{K => O}, Rest, Es};
                                        {error, E} ->
                                            {Os, Rest, [{map_value, K, E} | Es]}
                                    end
                            end
                    end,
                    {#{}, Input, []},
                    Schema
                ),

            {Output2, Errors2} =
                case maps:get(unknown_keys, Options, strip) of
                    strip ->
                        {Output1, Errors1};
                    passthrough ->
                        {maps:merge(Output1, RemainingMap), Errors1};
                    strict ->
                        {Output1, [{unknown_keys, maps:keys(RemainingMap)} | Errors1]}
                end,

            case Errors2 of
                [] ->
                    {ok, Output2};
                _ ->
                    {error, lists:reverse(Errors2)}
            end;
        (_Invalid) ->
            {error, [not_map]}
    end.

-doc """
Validate a homogeneous map where every key is parsed by `KZ` and every
value by `VZ`. Use this for caches, dictionaries, and other arbitrary-
keyed maps where the key shape is uniform.

Key errors are wrapped as `{map_key, OriginalKey, InnerErrors}`; value
errors are wrapped as `{map_value, OriginalKey, InnerErrors}`.

```erlang
zz:map_of(zz:binary(), zz:integer()).
```
""".
-spec map_of(parser(K), parser(V)) -> parser(#{K => V}).
map_of(KZ, VZ) ->
    fun
        (Input) when is_map(Input) ->
            {Out, Errs} =
                maps:fold(
                    fun(K, V, {Os, Es}) ->
                        case KZ(K) of
                            {ok, K2} ->
                                case VZ(V) of
                                    {ok, V2} ->
                                        {Os#{K2 => V2}, Es};
                                    {error, E} ->
                                        {Os, [{map_value, K, E} | Es]}
                                end;
                            {error, E} ->
                                {Os, [{map_key, K, E} | Es]}
                        end
                    end,
                    {#{}, []},
                    Input
                ),
            case Errs of
                [] -> {ok, Out};
                _ -> {error, lists:reverse(Errs)}
            end;
        (_Invalid) ->
            {error, [not_map]}
    end.

-doc """
Mark a parser as optional in a `t:schema/0`. Inside a `map/2` schema, an
optional key may be absent without producing an error.
""".
-spec optional(parser(T)) -> optional_parser(T).
optional(Z) ->
    {optional, Z}.

-doc """
Defer construction of a parser until parse time. Use to build
self-referential (recursive) schemas without infinite recursion at
definition time.

`Thunk` is called on every descent into the lazy parser, so it should
be cheap (typically just `fun() -> some_parser_fn() end`). The thunk
must return a fresh parser — returning the lazy parser itself would
loop forever at parse time.

```erlang
tree() ->
    zz:union([
        zz:literal(leaf),
        zz:tuple({
            zz:literal(node),
            zz:lazy(fun() -> tree() end),
            zz:lazy(fun() -> tree() end)
        })
    ]).
```
""".
-spec lazy(fun(() -> parser(T))) -> parser(T).
lazy(Thunk) ->
    fun(Input) ->
        Z = Thunk(),
        Z(Input)
    end.

-doc "Validate that input is a tuple (passthrough on contents).".
-spec tuple() -> parser(tuple()).
tuple() ->
    fun
        (Input) when is_tuple(Input) ->
            {ok, Input};
        (_Invalid) ->
            {error, [not_tuple]}
    end.

-doc """
Validate a fixed-arity tuple where each element is parsed by the
corresponding parser at the same position in `Zs`. Element errors
are wrapped as `{tuple, Index, InnerErrors}` with 1-based `Index`.
""".
-spec tuple(tuple()) -> parser(tuple()).
tuple(Zs) when is_tuple(Zs) ->
    Arity = tuple_size(Zs),
    ZsList = tuple_to_list(Zs),
    fun
        (Input) when is_tuple(Input), tuple_size(Input) =:= Arity ->
            Zip = lists:zip(ZsList, tuple_to_list(Input)),
            {_, O1, E1} =
                lists:foldl(
                    fun({Z, I}, {N, Os, Es}) ->
                        case Z(I) of
                            {ok, O} ->
                                {N + 1, [O | Os], Es};
                            {error, E} ->
                                {N + 1, Os, [{tuple, N, E} | Es]}
                        end
                    end,
                    {1, [], []},
                    Zip
                ),
            case E1 of
                [] ->
                    {ok, list_to_tuple(lists:reverse(O1))};
                _ ->
                    {error, lists:reverse(E1)}
            end;
        (Input) when is_tuple(Input) ->
            {error, [arity_mismatch]};
        (_Invalid) ->
            {error, [not_tuple]}
    end.

-doc """
Validate against the first parser that succeeds. If none match, returns
`{error, [{no_match, [Errors1, Errors2, ...]}]}` where each entry is the
errors list from the corresponding parser, in input order. Empty union
yields `{error, [{no_match, []}]}`.
""".
-spec union([parser(T)]) -> parser(T).
union(Zs) ->
    fun(Input) -> union_try(Zs, Input, []) end.

union_try([], _Input, Errs) ->
    {error, [{no_match, lists:reverse(Errs)}]};
union_try([Z | Rest], Input, Errs) ->
    case Z(Input) of
        {ok, _} = Ok -> Ok;
        {error, E} -> union_try(Rest, Input, [E | Errs])
    end.

-doc """
Flatten nested `t:errors/0` into a flat list of `t:issue/0` records,
each with a `path` to the failing position and a `code`.

Compound errors carry extra fields:
- `unknown_keys` issues include `keys => [term()]`.
- `no_match` issues include `branches => [issues()]`, one per union
  branch in input order.
- `invalid_key` issues (from `map_of/2` key validation) include
  `key => term()` (the offending key) and `errors => issues()`.
""".
-spec issues(errors()) -> issues().
issues(Errors) ->
    issues_at(Errors, []).

%% RevPath holds the path reversed during traversal; reversed once at
%% each leaf so the walk stays O(n) over the error tree instead of O(n^2).
-spec issues_at(errors(), path()) -> issues().
issues_at(Errors, RevPath) ->
    lists:flatmap(fun(E) -> issue(E, RevPath) end, Errors).

-spec issue(error(), path()) -> issues().
issue(Code, RevPath) when is_atom(Code) ->
    [#{path => lists:reverse(RevPath), code => Code}];
issue({list, N, Es}, RevPath) ->
    issues_at(Es, [N | RevPath]);
issue({tuple, N, Es}, RevPath) ->
    issues_at(Es, [N | RevPath]);
issue({map_missing, K}, RevPath) ->
    [#{path => lists:reverse([K | RevPath]), code => missing_key}];
issue({map_value, K, Es}, RevPath) ->
    issues_at(Es, [K | RevPath]);
issue({map_key, K, Es}, RevPath) ->
    [
        #{
            path => lists:reverse(RevPath),
            code => invalid_key,
            key => K,
            errors => issues(Es)
        }
    ];
issue({unknown_keys, Keys}, RevPath) ->
    [#{path => lists:reverse(RevPath), code => unknown_keys, keys => Keys}];
issue({no_match, Branches}, RevPath) ->
    [
        #{
            path => lists:reverse(RevPath),
            code => no_match,
            branches => [issues(B) || B <- Branches]
        }
    ].
