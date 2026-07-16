-module(non_neg_integer_tests).

-include("test.hrl").

zero_test() ->
    ?Z_OK(zz:non_neg_integer(), 0).

positive_test() ->
    ?Z_OK(zz:non_neg_integer(), 42).

negative_test() ->
    ?assertEqual(
        {error, [not_non_neg_integer]},
        zz:parse(zz:non_neg_integer(), -1)
    ).

positive_float_test() ->
    ?assertEqual(
        {error, [not_non_neg_integer]},
        zz:parse(zz:non_neg_integer(), 1.0)
    ).
