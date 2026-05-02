-module(binary_tests).

-include("test.hrl").

empty_binary_test() ->
    ?Z_OK(z:binary(), <<>>).

ascii_binary_test() ->
    ?Z_OK(z:binary(), <<"hello">>).

utf8_binary_test() ->
    ?Z_OK(z:binary(), <<"åäö👍">>).

string_input_is_not_binary_test() ->
    ?assertEqual({error, [not_binary]}, z:parse(z:binary(), "string")).

min_satisfied_test() ->
    ?Z_OK(z:binary(#{min => 1}), <<"a">>).

min_violated_test() ->
    ?assertEqual(
        {error, [binary_too_short]},
        z:parse(z:binary(#{min => 2}), <<"a">>)
    ).

max_satisfied_test() ->
    ?Z_OK(z:binary(#{max => 1}), <<"a">>).

max_violated_test() ->
    ?assertEqual(
        {error, [binary_too_long]},
        z:parse(z:binary(#{max => 2}), <<"abc">>)
    ).

regex_match_test() ->
    ?Z_OK(z:binary(#{regex => "^abc"}), <<"abcdef">>).

regex_mismatch_test() ->
    ?assertEqual(
        {error, [regex_mismatch]},
        z:parse(z:binary(#{regex => ".*f.*"}), <<"abc">>)
    ).

max_zero_allows_empty_test() ->
    Z = z:binary(#{max => 0}),
    ?Z_OK(Z, <<>>),
    ?assertEqual({error, [binary_too_long]}, z:parse(Z, <<"a">>)).

min_max_equal_test() ->
    Z = z:binary(#{min => 3, max => 3}),
    ?Z_OK(Z, <<"abc">>),
    ?assertEqual({error, [binary_too_short]}, z:parse(Z, <<"ab">>)),
    ?assertEqual({error, [binary_too_long]}, z:parse(Z, <<"abcd">>)).

combined_errors_test() ->
    Z = z:binary(#{regex => <<".*a.*">>, min => 5}),
    {error, Errs} = z:parse(Z, <<"xyz">>),
    ?assertEqual([binary_too_short, regex_mismatch], lists:sort(Errs)).
