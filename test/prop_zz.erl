-module(prop_zz).

-eqwalizer(ignore).

-include_lib("proper/include/proper.hrl").
-include_lib("eunit/include/eunit.hrl").

-define(VALID(Gen, Parser),
    ?FORALL({Input, Z}, {Gen, Parser}, begin
        {ok, Input} =:= zz:parse(Z, Input)
    end)
).

prop_any_identity() ->
    ?VALID(any(), zz:any()).

prop_atom_ok() ->
    ?VALID(atom(), zz:atom()).

prop_binary_ok() ->
    ?VALID(binary(), zz:binary()).

prop_boolean_ok() ->
    ?VALID(boolean(), zz:boolean()).

prop_integer_ok() ->
    ?VALID(integer(), zz:integer()).

prop_list_ok() ->
    ?VALID(list(), zz:list()).

prop_map_ok() ->
    ?VALID(map(), zz:map()).

prop_tuple_ok() ->
    ?VALID(tuple(), zz:tuple()).

prop_float_ok() ->
    ?VALID(float(), zz:float()).

prop_literal_ok() ->
    ?FORALL(T, ground_term(), {ok, T} =:= zz:parse(zz:literal(T), T)).

prop_union_ok() ->
    ?FORALL(
        {Input, Z},
        oneof([
            {integer(), zz:union([zz:integer(), zz:binary()])},
            {binary(), zz:union([zz:integer(), zz:binary()])},
            {boolean(), zz:union([zz:atom(), zz:integer()])}
        ]),
        {ok, Input} =:= zz:parse(Z, Input)
    ).

prop_atom_invalid() ->
    ?FORALL(
        X, not_atom(), {error, [not_atom]} =:= zz:parse(zz:atom(), X)
    ).

prop_boolean_invalid() ->
    ?FORALL(
        X, not_boolean(), {error, [not_boolean]} =:= zz:parse(zz:boolean(), X)
    ).

prop_binary_invalid() ->
    ?FORALL(
        X, not_binary(), {error, [not_binary]} =:= zz:parse(zz:binary(), X)
    ).

prop_integer_invalid() ->
    ?FORALL(
        X, not_integer(), {error, [not_integer]} =:= zz:parse(zz:integer(), X)
    ).

prop_float_invalid() ->
    ?FORALL(
        X, not_float(), {error, [not_float]} =:= zz:parse(zz:float(), X)
    ).

prop_list_invalid() ->
    ?FORALL(
        X, not_list(), {error, [not_list]} =:= zz:parse(zz:list(), X)
    ).

prop_tuple_invalid() ->
    ?FORALL(
        X, not_tuple(), {error, [not_tuple]} =:= zz:parse(zz:tuple(), X)
    ).

prop_map_invalid() ->
    ?FORALL(
        X, not_map(), {error, [not_map]} =:= zz:parse(zz:map(), X)
    ).

prop_issues_total() ->
    ?FORALL(
        {Input, Z},
        oneof([
            {not_atom(), zz:atom()},
            {not_binary(), zz:binary()},
            {not_boolean(), zz:boolean()},
            {not_integer(), zz:integer()},
            {not_float(), zz:float()},
            {not_list(), zz:list()},
            {not_tuple(), zz:tuple()},
            {not_map(), zz:map()},
            {any(), zz:literal(forty_two)},
            {any(), zz:union([zz:integer(), zz:binary()])},
            {any(), zz:list(zz:integer())},
            {any(), zz:tuple({zz:integer(), zz:binary()})},
            {any(), zz:map(#{name => zz:binary()})},
            {any(), zz:map(#{}, #{unknown_keys => strict})}
        ]),
        case zz:parse(Z, Input) of
            {ok, _} ->
                true;
            {error, Errs} ->
                Issues = zz:issues(Errs),
                is_list(Issues) andalso
                    lists:all(
                        fun(I) ->
                            is_map(I) andalso
                                maps:is_key(path, I) andalso
                                maps:is_key(code, I)
                        end,
                        Issues
                    )
        end
    ).

%%%===========================================================================
%%% GENERATORS
%%%===========================================================================

%% Ground-typed term — atoms, numbers, binaries, and small composites of
%% the same. Avoids `any()` so that `=:=` comparisons (for `literal/1`)
%% are stable.
ground_term() ->
    oneof([atom(), integer(), float(), binary(), boolean(), list(), tuple()]).

not_atom() ->
    oneof([integer(), float(), binary(), list(integer()), tuple(), map(atom(), integer())]).

not_boolean() ->
    ?SUCHTHAT(
        X,
        oneof([
            atom(), integer(), float(), binary(), list(integer()), tuple(), map(atom(), integer())
        ]),
        X =/= true andalso X =/= false
    ).

not_binary() ->
    oneof([atom(), integer(), float(), list(integer()), tuple(), map(atom(), integer())]).

not_integer() ->
    oneof([atom(), float(), binary(), list(integer()), tuple(), map(atom(), integer())]).

not_float() ->
    oneof([atom(), integer(), binary(), list(integer()), tuple(), map(atom(), integer())]).

not_list() ->
    oneof([atom(), integer(), float(), binary(), tuple(), map(atom(), integer())]).

not_tuple() ->
    oneof([atom(), integer(), float(), binary(), list(integer()), map(atom(), integer())]).

not_map() ->
    oneof([atom(), integer(), float(), binary(), list(integer()), tuple()]).
