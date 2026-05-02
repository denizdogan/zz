-module(integer_typed_tests).

-include("test.hrl").

%%%===========================================================================
%%% pos_integer/0
%%%===========================================================================

pos_integer_one_test() ->
    ?Z_OK(zz:pos_integer(), 1).

pos_integer_large_test() ->
    ?Z_OK(zz:pos_integer(), 1000).

pos_integer_zero_test() ->
    ?assertEqual({error, [not_pos_integer]}, zz:parse(zz:pos_integer(), 0)).

pos_integer_negative_test() ->
    ?assertEqual({error, [not_pos_integer]}, zz:parse(zz:pos_integer(), -5)).

pos_integer_float_test() ->
    ?assertEqual({error, [not_pos_integer]}, zz:parse(zz:pos_integer(), 1.0)).

pos_integer_atom_test() ->
    ?assertEqual({error, [not_pos_integer]}, zz:parse(zz:pos_integer(), foo)).

%%%===========================================================================
%%% non_neg_integer/0
%%%===========================================================================

non_neg_zero_test() ->
    ?Z_OK(zz:non_neg_integer(), 0).

non_neg_positive_test() ->
    ?Z_OK(zz:non_neg_integer(), 42).

non_neg_negative_test() ->
    ?assertEqual(
        {error, [not_non_neg_integer]},
        zz:parse(zz:non_neg_integer(), -1)
    ).

non_neg_atom_test() ->
    ?assertEqual(
        {error, [not_non_neg_integer]},
        zz:parse(zz:non_neg_integer(), foo)
    ).

%%%===========================================================================
%%% neg_integer/0
%%%===========================================================================

neg_minus_one_test() ->
    ?Z_OK(zz:neg_integer(), -1).

neg_large_test() ->
    ?Z_OK(zz:neg_integer(), -1000).

neg_zero_test() ->
    ?assertEqual({error, [not_neg_integer]}, zz:parse(zz:neg_integer(), 0)).

neg_positive_test() ->
    ?assertEqual({error, [not_neg_integer]}, zz:parse(zz:neg_integer(), 1)).

neg_atom_test() ->
    ?assertEqual({error, [not_neg_integer]}, zz:parse(zz:neg_integer(), foo)).
