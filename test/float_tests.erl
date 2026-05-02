-module(float_tests).

-include("test.hrl").

float_valid_test() ->
    ?Z_OK(zz:float(), 1.0),
    ?Z_OK(zz:float(), -0.1),
    ?Z_OK(zz:float(), +0.0),
    ?Z_OK(zz:float(), -0.0),
    ok.

float_invalid_test() ->
    ?assertEqual({error, [not_float]}, zz:parse(zz:float(), 1)),
    ?assertEqual({error, [not_float]}, zz:parse(zz:float(), <<"1.0">>)),
    ?assertEqual({error, [not_float]}, zz:parse(zz:float(), foo)),
    ?assertEqual({error, [not_float]}, zz:parse(zz:float(), [])),
    ok.

float_min_test() ->
    Z = zz:float(#{min => 3.0}),
    ?assertEqual({ok, 3.1}, zz:parse(Z, 3.1)),
    ?assertEqual({ok, 3.0}, zz:parse(Z, 3.0)),
    ?assertEqual({error, [float_too_small]}, zz:parse(Z, 2.999999)),
    ok.

float_max_test() ->
    Z = zz:float(#{max => 3.14}),
    ?assertEqual({ok, -3.14}, zz:parse(Z, -3.14)),
    ?assertEqual({ok, 3.14}, zz:parse(Z, 3.14)),
    ?assertEqual({error, [float_too_large]}, zz:parse(Z, 3.141)),
    ok.

float_min_max_test() ->
    Z = zz:float(#{max => 3.9, min => 4.1}),
    {error, Errs} = zz:parse(Z, 4.0),
    ?assertEqual([float_too_large, float_too_small], lists:sort(Errs)),
    ok.
