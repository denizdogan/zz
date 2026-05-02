-module(prop_z).

-eqwalizer(ignore).

-include_lib("proper/include/proper.hrl").
-include_lib("eunit/include/eunit.hrl").

-define(VALID(Gen, Parser),
    ?FORALL({Input, Z}, {Gen, Parser}, begin
        {ok, Input} =:= z:parse(Z, Input)
    end)
).

prop_atom_ok() ->
    ?VALID(atom(), z:atom()).

prop_binary_ok() ->
    ?VALID(binary(), z:binary()).

prop_boolean_ok() ->
    ?VALID(boolean(), z:boolean()).

prop_integer_ok() ->
    ?VALID(integer(), z:integer()).

prop_list_ok() ->
    ?VALID(list(), z:list()).

prop_map_ok() ->
    ?VALID(map(), z:map()).

prop_tuple_ok() ->
    ?VALID(tuple(), z:tuple()).

prop_float_ok() ->
    ?VALID(float(), z:float()).

prop_literal_ok() ->
    ?FORALL(T, ground_term(), {ok, T} =:= z:parse(z:literal(T), T)).

prop_union_ok() ->
    ?FORALL(
        {Input, Z},
        oneof([
            {integer(), z:union([z:integer(), z:binary()])},
            {binary(), z:union([z:integer(), z:binary()])},
            {boolean(), z:union([z:atom(), z:integer()])}
        ]),
        {ok, Input} =:= z:parse(Z, Input)
    ).

prop_atom_invalid() ->
    ?FORALL(
        X, not_atom(), {error, [not_atom]} =:= z:parse(z:atom(), X)
    ).

prop_boolean_invalid() ->
    ?FORALL(
        X, not_boolean(), {error, [not_boolean]} =:= z:parse(z:boolean(), X)
    ).

prop_binary_invalid() ->
    ?FORALL(
        X, not_binary(), {error, [not_binary]} =:= z:parse(z:binary(), X)
    ).

prop_integer_invalid() ->
    ?FORALL(
        X, not_integer(), {error, [not_integer]} =:= z:parse(z:integer(), X)
    ).

prop_float_invalid() ->
    ?FORALL(
        X, not_float(), {error, [not_float]} =:= z:parse(z:float(), X)
    ).

prop_list_invalid() ->
    ?FORALL(
        X, not_list(), {error, [not_list]} =:= z:parse(z:list(), X)
    ).

prop_tuple_invalid() ->
    ?FORALL(
        X, not_tuple(), {error, [not_tuple]} =:= z:parse(z:tuple(), X)
    ).

prop_map_invalid() ->
    ?FORALL(
        X, not_map(), {error, [not_map]} =:= z:parse(z:map(), X)
    ).

prop_basic() ->
    ?FORALL(
        {Input, Z},
        oneof([
            {atom(), z:atom()},
            {binary(), z:binary()},
            {boolean(), z:boolean()},
            {integer(), z:integer()},
            {float(), z:float()},
            {list(), z:list()},
            {map(), z:map()},
            {tuple(), z:tuple()}
        ]),
        {ok, Input} =:= z:parse(Z, Input)
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
