-module(tuple_tests).

-include("test.hrl").

%%%===========================================================================
%%% tuple/0 — any tuple, contents not validated
%%%===========================================================================

empty_tuple_test() ->
    ?Z_OK(zz:tuple(), {}).

singleton_tuple_test() ->
    ?Z_OK(zz:tuple(), {1}).

multi_element_tuple_test() ->
    ?Z_OK(zz:tuple(), {1, 2, 3, 4, 5, 6, 7}).

list_input_is_not_tuple_test() ->
    ?assertEqual({error, [not_tuple]}, zz:parse(zz:tuple(), [])).

list_with_elements_input_is_not_tuple_test() ->
    ?assertEqual({error, [not_tuple]}, zz:parse(zz:tuple(), [1, 2])).

binary_input_is_not_tuple_test() ->
    ?assertEqual({error, [not_tuple]}, zz:parse(zz:tuple(), <<"x">>)).

integer_input_is_not_tuple_test() ->
    ?assertEqual({error, [not_tuple]}, zz:parse(zz:tuple(), 1)).

atom_input_is_not_tuple_test() ->
    ?assertEqual({error, [not_tuple]}, zz:parse(zz:tuple(), foo)).

map_input_is_not_tuple_test() ->
    ?assertEqual({error, [not_tuple]}, zz:parse(zz:tuple(), #{})).

%%%===========================================================================
%%% tuple/1 — fixed-arity, per-position parsers
%%%===========================================================================

empty_tuple_schema_test() ->
    ?assertEqual({ok, {}}, zz:parse(zz:tuple([]), {})).

empty_schema_arity_mismatch_test() ->
    ?assertEqual({error, [arity_mismatch]}, zz:parse(zz:tuple([]), {1})).

fixed_arity_match_test() ->
    Z = zz:tuple([zz:integer(), zz:binary()]),
    ?assertEqual({ok, {3, <<"foo">>}}, zz:parse(Z, {3, <<"foo">>})).

fixed_arity_too_short_test() ->
    Z = zz:tuple([zz:integer(), zz:binary()]),
    ?assertEqual({error, [arity_mismatch]}, zz:parse(Z, {1})).

fixed_arity_too_long_test() ->
    Z = zz:tuple([zz:integer(), zz:binary()]),
    ?assertEqual({error, [arity_mismatch]}, zz:parse(Z, {1, <<"a">>, extra})).

fixed_arity_position_errors_test() ->
    Z = zz:tuple([zz:integer(), zz:binary()]),
    ?assertEqual(
        {error, [
            {tuple, 1, [not_integer]},
            {tuple, 2, [not_binary]}
        ]},
        zz:parse(Z, {<<"three">>, foo})
    ).

fixed_arity_non_tuple_input_test() ->
    Z = zz:tuple([zz:integer()]),
    ?assertEqual({error, [not_tuple]}, zz:parse(Z, [1])),
    ?assertEqual({error, [not_tuple]}, zz:parse(Z, 1)).
