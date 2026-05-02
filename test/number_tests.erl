-module(number_tests).

-include("test.hrl").

integer_test() ->
    ?Z_OK(zz:number(), 1).

negative_integer_test() ->
    ?Z_OK(zz:number(), -42).

zero_test() ->
    ?Z_OK(zz:number(), 0).

float_test() ->
    ?Z_OK(zz:number(), 3.14).

negative_float_test() ->
    ?Z_OK(zz:number(), -2.5).

atom_test() ->
    ?assertEqual({error, [not_number]}, zz:parse(zz:number(), foo)).

binary_test() ->
    ?assertEqual({error, [not_number]}, zz:parse(zz:number(), <<"1">>)).

list_test() ->
    ?assertEqual({error, [not_number]}, zz:parse(zz:number(), [1])).
