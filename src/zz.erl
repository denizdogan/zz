-module(zz).

-moduledoc """
Zod-like parsing and validation for Erlang.

Each combinator returns a `t:parser/1` (or `t:optional_parser/1` from
`optional/1`). Compose them, then run with `parse/2`:

```erlang
Z = zz:map(#{name => zz:binary(), age => zz:integer(#{min => 0})}),
{ok, User} = zz:parse(Z, #{name => <<"x">>, age => 1}),
<<"x">> = maps:get(name, User).
```

On failure, the nested `t:errors/0` shape can be flattened to a
path-addressed list of issues with `issues/1`, or rendered to a
human-readable binary with `format_issues/1`.
""".

-compile({no_auto_import, [float/1]}).

%% iodata/0 and iolist/0 narrow input from term() to iodata/iolist via
%% try iolist_size(...) — eqwalizer can't reason about that flow, so
%% it would reject the precise specs. The runtime check is the
%% validation; we keep the precise return type and skip static checking
%% for these two functions only.
-eqwalizer({nowarn_function, iodata/0}).
-eqwalizer({nowarn_function, iolist/0}).

-export([
    any/0,
    atom/0,
    binary/0,
    binary/1,
    bitstring/0,
    bitstring/1,
    boolean/0,
    char/0,
    char_list/0,
    enum/1,
    float/0,
    float/1,
    format_issues/1,
    function/0,
    function/1,
    integer/0,
    integer/1,
    iodata/0,
    iolist/0,
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
    map_of/3,
    neg_integer/0,
    non_neg_integer/0,
    nullable/1,
    number/0,
    optional/1,
    parse/2,
    pid/0,
    pos_integer/0,
    reference/0,
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
    bitstring_options/0,
    integer_options/0,
    float_options/0,
    list_options/0,
    map_options/0,
    map_of_options/0,
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
    | {map_key_collision, term()}
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
-type bitstring_options() :: #{min => non_neg_integer(), max => non_neg_integer()}.
-type integer_options() :: #{min => integer(), max => integer()}.
-type float_options() :: #{min => float(), max => float()}.
-type list_options() :: #{min => non_neg_integer(), max => non_neg_integer()}.
-type map_options() :: #{unknown_keys => strip | passthrough | strict}.
-type map_of_options() :: #{on_collision => error | overwrite}.
-type schema() :: #{term() => parser() | optional_parser()}.

-doc "Run parser `Z` against `Input`.".
-spec parse(parser(T), term()) -> result(T).
parse(Z, Input) ->
    Z(Input).

-doc "Accept any input. Output equals input.".
-spec any() -> parser(term()).
any() ->
    fun(Input) -> {ok, Input} end.

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
    Min = maps:get(min, Options, undefined),
    Max = maps:get(max, Options, undefined),
    Regex = maps:get(regex, Options, undefined),
    fun
        (Input) when is_binary(Input) ->
            Sz = byte_size(Input),
            Errs0 =
                if
                    is_integer(Min), Sz < Min -> [binary_too_short];
                    true -> []
                end,
            Errs1 =
                if
                    is_integer(Max), Sz > Max -> [binary_too_long | Errs0];
                    true -> Errs0
                end,
            Errs2 =
                case Regex of
                    undefined ->
                        Errs1;
                    _ ->
                        case re:run(Input, Regex) of
                            nomatch -> [regex_mismatch | Errs1];
                            _ -> Errs1
                        end
                end,
            case Errs2 of
                [] -> {ok, Input};
                _ -> {error, Errs2}
            end;
        (_Invalid) ->
            {error, [not_binary]}
    end.

-doc #{equiv => bitstring / 1}.
-spec bitstring() -> parser(bitstring()).
bitstring() ->
    bitstring(#{}).

-doc """
Validate that input is a bitstring, with optional `min`/`max`
`bit_size/1` constraints.
""".
-spec bitstring(bitstring_options()) -> parser(bitstring()).
bitstring(Options) ->
    Min = maps:get(min, Options, undefined),
    Max = maps:get(max, Options, undefined),
    fun
        (Input) when is_bitstring(Input) ->
            Sz = bit_size(Input),
            Errs0 =
                if
                    is_integer(Min), Sz < Min -> [bitstring_too_short];
                    true -> []
                end,
            Errs1 =
                if
                    is_integer(Max), Sz > Max -> [bitstring_too_long | Errs0];
                    true -> Errs0
                end,
            case Errs1 of
                [] -> {ok, Input};
                _ -> {error, Errs1}
            end;
        (_Invalid) ->
            {error, [not_bitstring]}
    end.

-doc """
Validate that input is `iodata()` (a binary or `iolist()`). Validation
walks the entire structure via `iolist_size/1`, so cost is linear in
the total bytes addressed.
""".
-spec iodata() -> parser(iodata()).
iodata() ->
    fun(Input) ->
        try iolist_size(Input) of
            _ -> {ok, Input}
        catch
            error:badarg -> {error, [not_iodata]}
        end
    end.

-doc """
Validate that input is an `iolist()` (a possibly-improper list of
bytes, binaries, and nested iolists). Use `iodata/0` if a raw binary
should also be accepted.
""".
-spec iolist() -> parser(iolist()).
iolist() ->
    fun
        (Input) when is_list(Input) ->
            try iolist_size(Input) of
                _ -> {ok, Input}
            catch
                error:badarg -> {error, [not_iolist]}
            end;
        (_Invalid) ->
            {error, [not_iolist]}
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

-doc """
Validate that input is a single Unicode codepoint (`t:char/0`), an
integer in `0..16#10FFFF`.
""".
-spec char() -> parser(char()).
char() ->
    fun
        (Input) when is_integer(Input), Input >= 0, Input =< 16#10FFFF ->
            {ok, Input};
        (_Invalid) ->
            {error, [not_char]}
    end.

-doc """
Validate that input is a list of Unicode codepoints (`[char()]`),
i.e. the old-style Erlang string representation. Element errors are
wrapped as `{list, Index, [not_char]}`.
""".
-spec char_list() -> parser([char()]).
char_list() ->
    list(char()).

-doc "Validate that input is a process identifier.".
-spec pid() -> parser(pid()).
pid() ->
    fun
        (Input) when is_pid(Input) ->
            {ok, Input};
        (_Invalid) ->
            {error, [not_pid]}
    end.

-doc "Validate that input is a reference (e.g. from `make_ref/0`).".
-spec reference() -> parser(reference()).
reference() ->
    fun
        (Input) when is_reference(Input) ->
            {ok, Input};
        (_Invalid) ->
            {error, [not_reference]}
    end.

-doc #{equiv => integer / 1}.
-spec integer() -> parser(integer()).
integer() ->
    integer(#{}).

-doc "Validate that input is an integer, with optional `min`/`max`.".
-spec integer(integer_options()) -> parser(integer()).
integer(Options) ->
    Min = maps:get(min, Options, undefined),
    Max = maps:get(max, Options, undefined),
    fun
        (Input) when is_integer(Input) ->
            Errs0 =
                if
                    is_integer(Min), Input < Min -> [integer_too_small];
                    true -> []
                end,
            Errs1 =
                if
                    is_integer(Max), Input > Max -> [integer_too_large | Errs0];
                    true -> Errs0
                end,
            case Errs1 of
                [] -> {ok, Input};
                _ -> {error, Errs1}
            end;
        (_Invalid) ->
            {error, [not_integer]}
    end.

-doc "Validate that input is a positive integer (>= 1).".
-spec pos_integer() -> parser(pos_integer()).
pos_integer() ->
    fun
        (Input) when is_integer(Input), Input >= 1 ->
            {ok, Input};
        (_Invalid) ->
            {error, [not_pos_integer]}
    end.

-doc "Validate that input is a non-negative integer (>= 0).".
-spec non_neg_integer() -> parser(non_neg_integer()).
non_neg_integer() ->
    fun
        (Input) when is_integer(Input), Input >= 0 ->
            {ok, Input};
        (_Invalid) ->
            {error, [not_non_neg_integer]}
    end.

-doc "Validate that input is a negative integer (=< -1).".
-spec neg_integer() -> parser(neg_integer()).
neg_integer() ->
    fun
        (Input) when is_integer(Input), Input =< -1 ->
            {ok, Input};
        (_Invalid) ->
            {error, [not_neg_integer]}
    end.

-doc #{equiv => float / 1}.
-spec float() -> parser(float()).
float() ->
    float(#{}).

-doc "Validate that input is a float, with optional `min`/`max`.".
-spec float(float_options()) -> parser(float()).
float(Options) ->
    Min = maps:get(min, Options, undefined),
    Max = maps:get(max, Options, undefined),
    fun
        (Input) when is_float(Input) ->
            Errs0 =
                if
                    is_float(Min), Input < Min -> [float_too_small];
                    true -> []
                end,
            Errs1 =
                if
                    is_float(Max), Input > Max -> [float_too_large | Errs0];
                    true -> Errs0
                end,
            case Errs1 of
                [] -> {ok, Input};
                _ -> {error, Errs1}
            end;
        (_Invalid) ->
            {error, [not_float]}
    end.

-doc "Validate that input is a function (any arity).".
-spec function() -> parser(fun()).
function() ->
    fun
        (Input) when is_function(Input) ->
            {ok, Input};
        (_Invalid) ->
            {error, [not_function]}
    end.

-doc "Validate that input is a function with the given arity.".
-spec function(arity()) -> parser(fun()).
function(Arity) ->
    fun
        (Input) when is_function(Input, Arity) ->
            {ok, Input};
        (Input) when is_function(Input) ->
            {error, [function_arity_mismatch]};
        (_Invalid) ->
            {error, [not_function]}
    end.

-doc "Validate that input is a number (integer or float).".
-spec number() -> parser(number()).
number() ->
    fun
        (Input) when is_number(Input) ->
            {ok, Input};
        (_Invalid) ->
            {error, [not_number]}
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
    Min = maps:get(min, Options, undefined),
    Max = maps:get(max, Options, undefined),
    fun
        (Input) when is_list(Input) ->
            Len = length(Input),
            if
                is_integer(Max), Len > Max ->
                    {error, [list_too_long]};
                is_integer(Min), Len < Min ->
                    {error, [list_too_short]};
                true ->
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
                        [] -> {ok, lists:reverse(O1)};
                        _ -> {error, lists:reverse(E1)}
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
    fun
        (Input) when is_map(Input) ->
            {ok, Input};
        (_Invalid) ->
            {error, [not_map]}
    end.

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
    Mode = maps:get(unknown_keys, Options, strip),
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
                case Mode of
                    strip ->
                        {Output1, Errors1};
                    passthrough ->
                        {maps:merge(Output1, RemainingMap), Errors1};
                    strict when map_size(RemainingMap) =:= 0 ->
                        {Output1, Errors1};
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
    map_of(KZ, VZ, #{}).

-doc """
Like `map_of/2`, with an `on_collision` policy for distinct input keys
that parse to the same output key. The default is `error`; `overwrite`
keeps whichever value is visited last by the map iterator.
""".
-spec map_of(parser(K), parser(V), map_of_options()) -> parser(#{K => V}).
map_of(KZ, VZ, Options) ->
    OnCollision = maps:get(on_collision, Options, error),
    fun
        (Input) when is_map(Input) ->
            {Out, Errs} =
                maps:fold(
                    fun(K, V, {Os, Es}) ->
                        case KZ(K) of
                            {ok, K2} ->
                                case VZ(V) of
                                    {ok, _V2} when OnCollision =:= error, is_map_key(K2, Os) ->
                                        {Os, [{map_key_collision, K2} | Es]};
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

-doc """
Validate that input equals (`=:=`) one of `Values`. Fails with
`not_in_enum` if no value matches. Equivalent to a `union/1` of
`literal/1`s but with a flat error code.
""".
-spec enum([T]) -> parser(T).
enum(Values) ->
    fun(Input) -> enum_match(Input, Values) end.

-doc """
Validate that input is `undefined` or matches `Z`. Sugar for
`union([literal(undefined), Z])`.
""".
-spec nullable(parser(T)) -> parser(T | undefined).
nullable(Z) ->
    union([literal(undefined), Z]).

enum_match(_, []) ->
    {error, [not_in_enum]};
enum_match(Input, [V | _]) when Input =:= V ->
    {ok, V};
enum_match(Input, [_ | Rest]) ->
    enum_match(Input, Rest).

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
issue({map_key_collision, K}, RevPath) ->
    [#{path => lists:reverse(RevPath), code => map_key_collision, key => K}];
issue({unknown_keys, Keys}, RevPath) ->
    [#{path => lists:reverse(RevPath), code => unknown_keys, keys => Keys}];
issue({no_match, Branches}, RevPath) ->
    [
        #{
            path => lists:reverse(RevPath),
            code => no_match,
            branches => [issues_at(B, RevPath) || B <- Branches]
        }
    ].

-doc """
Format `t:issues/0` as a human-readable binary, one issue per line in
the form `path: code [extras]`. Empty paths render as `(root)`.
Useful for logs and human-facing error output.
""".
-spec format_issues(issues()) -> binary().
format_issues(Issues) ->
    iolist_to_binary([format_issue(I) || I <- Issues]).

format_issue(#{path := Path, code := Code} = Issue) ->
    Extras = maps:without([path, code], Issue),
    [format_path(Path), ": ", atom_to_binary(Code), format_extras(Extras), $\n].

format_path([]) ->
    <<"(root)">>;
format_path(Segs) ->
    lists:join($., [format_seg(S) || S <- Segs]).

format_seg(S) when is_atom(S) -> atom_to_binary(S);
format_seg(S) when is_integer(S) -> integer_to_binary(S);
format_seg(S) when is_binary(S) -> S;
format_seg(S) -> io_lib:format("~tp", [S]).

format_extras(Map) when map_size(Map) =:= 0 ->
    <<>>;
format_extras(Map) ->
    [" ", io_lib:format("~tp", [Map])].
