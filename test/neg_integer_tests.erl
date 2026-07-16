-module(neg_integer_tests).

-include("test.hrl").

minus_one_test() ->
    ?Z_OK(zz:neg_integer(), -1).

large_test() ->
    ?Z_OK(zz:neg_integer(), -1000).

zero_test() ->
    ?assertEqual({error, [not_neg_integer]}, zz:parse(zz:neg_integer(), 0)).

positive_test() ->
    ?assertEqual({error, [not_neg_integer]}, zz:parse(zz:neg_integer(), 1)).

negative_float_test() ->
    ?assertEqual({error, [not_neg_integer]}, zz:parse(zz:neg_integer(), -1.0)).
