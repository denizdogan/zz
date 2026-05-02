-module(boolean_tests).

-include("test.hrl").

boolean_valid_test() ->
    ?Z_OK(z:boolean(), true),
    ?Z_OK(z:boolean(), false),
    ok.

boolean_invalid_test() ->
    Z = z:boolean(),
    ?assertEqual({error, [not_boolean]}, z:parse(Z, <<"false">>)),
    ?assertEqual({error, [not_boolean]}, z:parse(Z, 0)),
    ?assertEqual({error, [not_boolean]}, z:parse(Z, 1)),
    ?assertEqual({error, [not_boolean]}, z:parse(Z, truthy)),
    ?assertEqual({error, [not_boolean]}, z:parse(Z, [])),
    ok.
