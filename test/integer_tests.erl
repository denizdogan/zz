-module(integer_tests).

-include("test.hrl").

integer_valid_test() ->
    ?Z_OK(z:integer(), 0),
    ?Z_OK(z:integer(), 19),
    ?Z_OK(z:integer(), -27),
    ?Z_OK(z:integer(), -99999999999999999999999999999999999999999999),
    ?Z_OK(z:integer(), 99999999999999999999999999999999999999999999),
    ?Z_OK(z:integer(), $a),
    ok.

integer_min_satisfied_test() ->
    ?Z_OK(z:integer(#{min => 3}), 3),
    ?Z_OK(z:integer(#{min => 3}), 100),
    ok.

integer_max_satisfied_test() ->
    ?Z_OK(z:integer(#{max => 3}), 3),
    ?Z_OK(z:integer(#{max => 3}), -100),
    ok.

integer_invalid_test() ->
    % input is not integer
    ?assertEqual(
        {error, [not_integer]},
        z:parse(z:integer(), <<"foo">>)
    ),

    % input is too small
    ?assertEqual(
        {error, [integer_too_small]},
        z:parse(z:integer(#{min => 3}), 2)
    ),

    % input is too large
    ?assertEqual(
        {error, [integer_too_large]},
        z:parse(z:integer(#{max => 3}), 4)
    ),

    % input is both too large and too small
    {error, Errs} = z:parse(z:integer(#{max => 3, min => 5}), 4),
    ?assertEqual([integer_too_large, integer_too_small], lists:sort(Errs)),

    ok.
