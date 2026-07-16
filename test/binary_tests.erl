-module(binary_tests).

-eqwalizer({nowarn_function, unicode_regex_with_invalid_utf8_returns_mismatch_test/0}).

-include("test.hrl").

empty_binary_test() ->
    ?Z_OK(zz:binary(), <<>>).

ascii_binary_test() ->
    ?Z_OK(zz:binary(), <<"hello">>).

utf8_binary_test() ->
    ?Z_OK(zz:binary(), <<"åäö👍">>).

string_input_is_not_binary_test() ->
    ?assertEqual({error, [not_binary]}, zz:parse(zz:binary(), "string")).

non_byte_aligned_bitstring_test() ->
    ?assertEqual({error, [not_binary]}, zz:parse(zz:binary(), <<1:7>>)).

utf8_byte_count_boundaries_test() ->
    Z = zz:binary(#{min => 4, max => 4}),
    ?Z_OK(Z, <<16#1F44D/utf8>>),
    ?assertEqual(
        {error, [binary_too_short]},
        zz:parse(Z, <<16#20AC/utf8>>)
    ),
    ?assertEqual(
        {error, [binary_too_long]},
        zz:parse(Z, <<16#1F44D/utf8, $!>>)
    ).

regex_match_test() ->
    ?Z_OK(zz:binary(#{regex => "^abc"}), <<"abcdef">>).

regex_mismatch_test() ->
    ?assertEqual(
        {error, [regex_mismatch]},
        zz:parse(zz:binary(#{regex => ".*f.*"}), <<"abc">>)
    ).

compiled_regex_test() ->
    {ok, Regex} = re:compile("^abc"),
    ?Z_OK(zz:binary(#{regex => Regex}), <<"abcdef">>).

unicode_regex_with_invalid_utf8_returns_mismatch_test() ->
    {ok, Regex} = re:compile(<<".">>, [unicode]),
    ?assertEqual(
        {error, [regex_mismatch]},
        zz:parse(zz:binary(#{regex => Regex}), <<255>>)
    ).

invalid_regex_fails_at_construction_test() ->
    ?assertError({invalid_regex, _}, zz:binary(#{regex => <<"(">>})).

max_zero_allows_empty_test() ->
    Z = zz:binary(#{max => 0}),
    ?Z_OK(Z, <<>>),
    ?assertEqual({error, [binary_too_long]}, zz:parse(Z, <<"a">>)).

combined_errors_test() ->
    Z = zz:binary(#{regex => <<".*a.*">>, min => 5}),
    {error, Errs} = zz:parse(Z, <<"xyz">>),
    ?assertEqual([binary_too_short, regex_mismatch], lists:sort(Errs)).
