-module(zz).

-moduledoc """
Zod-like parsing and validation for Erlang.

Each combinator returns a `t:parser/0` — a function from input to a
`t:result/1`. Compose them, then run with `parse/2`:

```erlang
Z = zz:map(#{name => zz:binary(), age => zz:integer(#{min => 0})}),
{ok, _} = zz:parse(Z, #{name => <<"x">>, age => 1}).
```
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
    list/0,
    list/1,
    list/2,
    literal/1,
    map/0,
    map/1,
    map/2,
    optional/1,
    parse/2,
    tuple/0,
    tuple/1,
    union/1
]).

-export_type([
    parser/0,
    optional_parser/0,
    result/1,
    errors/0,
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
    | {map, term(), errors() | missing_key}
    | {unknown_keys, [term()]}
    | {no_match, [errors()]}.

-type parser() :: fun((term()) -> result(term())).
-type optional_parser() :: {optional, parser()}.

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
-spec parse(parser(), term()) -> result(term()).
parse(Z, Input) ->
    Z(Input).

-doc "Validate that input is an atom.".
-spec atom() -> parser().
atom() ->
    fun
        (Input) when is_atom(Input) ->
            {ok, Input};
        (_Invalid) ->
            {error, [not_atom]}
    end.

-doc "Validate that input is a binary.".
-spec binary() -> parser().
binary() ->
    binary(#{}).

-doc """
Validate that input is a binary, with optional `min`/`max` byte size and
`regex` constraints.
""".
-spec binary(binary_options()) -> parser().
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
-spec boolean() -> parser().
boolean() ->
    fun
        (Input) when is_boolean(Input) ->
            {ok, Input};
        (_Invalid) ->
            {error, [not_boolean]}
    end.

-doc "Validate that input is an integer.".
-spec integer() -> parser().
integer() ->
    integer(#{}).

-doc "Validate that input is an integer, with optional `min`/`max`.".
-spec integer(integer_options()) -> parser().
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

-doc "Validate that input is a float.".
-spec float() -> parser().
float() ->
    float(#{}).

-doc "Validate that input is a float, with optional `min`/`max`.".
-spec float(float_options()) -> parser().
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
-spec list() -> parser().
list() ->
    fun
        (Input) when is_list(Input) ->
            {ok, Input};
        (_Invalid) ->
            {error, [not_list]}
    end.

-doc """
With a list of parsers, validate a fixed-length tuple-like list where each
element is parsed by the corresponding parser.

With a single parser, validate a homogeneous list (equivalent to
`list(Z, #{})`).
""".
-spec list([parser()] | parser()) -> parser().
list(Zs) when is_list(Zs) ->
    Length = length(Zs),
    fun
        (Input) when is_list(Input), length(Input) =:= Length ->
            Zip = lists:zip(Zs, Input),
            {_, O1, E1} =
                lists:foldl(
                    fun({Z, I}, {N, Os, Es}) ->
                        case Z(I) of
                            {ok, O} ->
                                {N + 1, [O | Os], Es};
                            {error, E} ->
                                {N + 1, Os, [{list, N, E} | Es]}
                        end
                    end,
                    {1, [], []},
                    Zip
                ),
            case E1 of
                [] ->
                    {ok, lists:reverse(O1)};
                _ ->
                    {error, lists:reverse(E1)}
            end;
        (Input) when is_list(Input) ->
            {error, [length_mismatch]};
        (_Invalid) ->
            {error, [not_list]}
    end;
list(Z) ->
    list(Z, #{}).

-doc """
Validate a homogeneous list, parsing each element with `Z`. Optional
`min`/`max` constrain length.
""".
-spec list(parser(), list_options()) -> parser().
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
-spec literal(term()) -> parser().
literal(Value) ->
    fun
        (Input) when Input =:= Value ->
            {ok, Input};
        (_Invalid) ->
            {error, [not_literal]}
    end.

-doc "Validate that input is a map (passthrough on contents).".
-spec map() -> parser().
map() ->
    map(#{}, #{unknown_keys => passthrough}).

-doc "Validate a map against `Schema` (equivalent to `map(Schema, #{})`).".
-spec map(schema()) -> parser().
map(Schema) ->
    map(Schema, #{}).

-doc """
Validate a map against `Schema`. `unknown_keys` controls handling of keys
not in `Schema`: `strip` (drop, default), `passthrough` (keep), `strict`
(error).
""".
-spec map(schema(), map_options()) -> parser().
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
                                            {Os, Rest, [{map, K, E} | Es]}
                                    end
                            end;
                        (K, Z, {Os, Is, Es}) ->
                            case maps:take(K, Is) of
                                error ->
                                    {Os, Is, [{map, K, missing_key} | Es]};
                                {Value, Rest} ->
                                    case Z(Value) of
                                        {ok, O} ->
                                            {Os#{K => O}, Rest, Es};
                                        {error, E} ->
                                            {Os, Rest, [{map, K, E} | Es]}
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
Mark a parser as optional in a `t:schema/0`. Inside a `map/2` schema, an
optional key may be absent without producing an error.
""".
-spec optional(parser()) -> optional_parser().
optional(Z) ->
    {optional, Z}.

-doc "Validate that input is a tuple (passthrough on contents).".
-spec tuple() -> parser().
tuple() ->
    fun
        (Input) when is_tuple(Input) ->
            {ok, Input};
        (_Invalid) ->
            {error, [not_tuple]}
    end.

-doc """
Validate a fixed-arity tuple where each element is parsed by the
corresponding parser in `Zs`. Element errors are wrapped as
`{tuple, Index, InnerErrors}` with 1-based `Index`.
""".
-spec tuple([parser()]) -> parser().
tuple(Zs) when is_list(Zs) ->
    Arity = length(Zs),
    fun
        (Input) when is_tuple(Input), tuple_size(Input) =:= Arity ->
            Zip = lists:zip(Zs, tuple_to_list(Input)),
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
-spec union([parser()]) -> parser().
union(Zs) ->
    fun(Input) -> try_branches(Zs, Input, []) end.

%%%===========================================================================
%%% Internal functions
%%%===========================================================================

try_branches([], _Input, Errs) ->
    {error, [{no_match, lists:reverse(Errs)}]};
try_branches([Z | Rest], Input, Errs) ->
    case Z(Input) of
        {ok, _} = Ok -> Ok;
        {error, E} -> try_branches(Rest, Input, [E | Errs])
    end.
