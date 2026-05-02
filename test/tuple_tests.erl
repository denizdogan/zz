-module(tuple_tests).

-include("test.hrl").

%%%===========================================================================
%%% tuple/0 — any tuple, contents not validated
%%%===========================================================================

empty_tuple_test() ->
    ?Z_OK(z:tuple(), {}).

singleton_tuple_test() ->
    ?Z_OK(z:tuple(), {1}).

multi_element_tuple_test() ->
    ?Z_OK(z:tuple(), {1, 2, 3, 4, 5, 6, 7}).

list_input_is_not_tuple_test() ->
    ?assertEqual({error, [not_tuple]}, z:parse(z:tuple(), [])).

list_with_elements_input_is_not_tuple_test() ->
    ?assertEqual({error, [not_tuple]}, z:parse(z:tuple(), [1, 2])).

binary_input_is_not_tuple_test() ->
    ?assertEqual({error, [not_tuple]}, z:parse(z:tuple(), <<"x">>)).

integer_input_is_not_tuple_test() ->
    ?assertEqual({error, [not_tuple]}, z:parse(z:tuple(), 1)).

atom_input_is_not_tuple_test() ->
    ?assertEqual({error, [not_tuple]}, z:parse(z:tuple(), foo)).

map_input_is_not_tuple_test() ->
    ?assertEqual({error, [not_tuple]}, z:parse(z:tuple(), #{})).

%%%===========================================================================
%%% tuple/1 — fixed-arity, per-position parsers
%%%===========================================================================

empty_tuple_schema_test() ->
    ?assertEqual({ok, {}}, z:parse(z:tuple([]), {})).

empty_schema_arity_mismatch_test() ->
    ?assertEqual({error, [arity_mismatch]}, z:parse(z:tuple([]), {1})).

fixed_arity_match_test() ->
    Z = z:tuple([z:integer(), z:binary()]),
    ?assertEqual({ok, {3, <<"foo">>}}, z:parse(Z, {3, <<"foo">>})).

fixed_arity_too_short_test() ->
    Z = z:tuple([z:integer(), z:binary()]),
    ?assertEqual({error, [arity_mismatch]}, z:parse(Z, {1})).

fixed_arity_too_long_test() ->
    Z = z:tuple([z:integer(), z:binary()]),
    ?assertEqual({error, [arity_mismatch]}, z:parse(Z, {1, <<"a">>, extra})).

fixed_arity_position_errors_test() ->
    Z = z:tuple([z:integer(), z:binary()]),
    ?assertEqual(
        {error, [
            {tuple, 1, [not_integer]},
            {tuple, 2, [not_binary]}
        ]},
        z:parse(Z, {<<"three">>, foo})
    ).

fixed_arity_non_tuple_input_test() ->
    Z = z:tuple([z:integer()]),
    ?assertEqual({error, [not_tuple]}, z:parse(Z, [1])),
    ?assertEqual({error, [not_tuple]}, z:parse(Z, 1)).
