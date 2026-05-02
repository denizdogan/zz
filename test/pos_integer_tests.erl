-module(pos_integer_tests).

-include("test.hrl").

one_test() ->
    ?Z_OK(zz:pos_integer(), 1).

large_test() ->
    ?Z_OK(zz:pos_integer(), 1000).

zero_test() ->
    ?assertEqual({error, [not_pos_integer]}, zz:parse(zz:pos_integer(), 0)).

negative_test() ->
    ?assertEqual({error, [not_pos_integer]}, zz:parse(zz:pos_integer(), -5)).

float_test() ->
    ?assertEqual({error, [not_pos_integer]}, zz:parse(zz:pos_integer(), 1.0)).

atom_test() ->
    ?assertEqual({error, [not_pos_integer]}, zz:parse(zz:pos_integer(), foo)).
